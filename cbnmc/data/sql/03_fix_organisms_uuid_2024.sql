CREATE OR REPLACE FUNCTION public.merge_id(schema_name text, table_name text, old_id int, new_id int)
RETURNS int AS
$$
DECLARE
    foreign_key RECORD;
    all_foreign_key_table text;
    update_query text;
    primary_keys_tables text;
    select_query text;
    join_select_query text;
    delete_query text;
    nb_iteration int;
    record_delete RECORD;
    val RECORD;
    pk_query text;
BEGIN
    /*
    * Recherche de toutes les clefs étrangères d'une table
    * mytablename : nom de la table d'origine
    * mycolumns : nom du champ d'origine
    * referredschema : nom du schema de la table comportant une clef étrangère sur latable d'origine
    * referredtable : nom de la table comportant une clef étrangère sur la table d'origine
    * referrefcolumn : nom de la clef étrangère sur la table d'origine
    */
    all_foreign_key_table :=   'SELECT TC.table_name AS mytablename,
                KCU.column_name AS mycolumns,
                ALLFOREIGNKEY.table_schema AS referedschema,
                ALLFOREIGNKEY.table_name AS referredtable,
                ALLFOREIGNKEY.column_name AS referredcolumn
        FROM  information_schema.table_constraints AS TC
        JOIN (
            SELECT table_schema, table_name, column_name, unique_constraint_name
            FROM information_schema.referential_constraints RC
            INNER JOIN information_schema.key_column_usage AS KCU
                ON RC.constraint_name = KCU.constraint_name
        ) AS ALLFOREIGNKEY ON TC.constraint_name = ALLFOREIGNKEY.unique_constraint_name
        INNER JOIN information_schema.key_column_usage AS KCU
            ON TC.constraint_name = KCU.constraint_name
        WHERE TC.constraint_type = ''PRIMARY KEY''
            AND TC.table_schema = KCU.table_schema
            AND TC.table_schema = '''||schema_name||'''
            AND TC.table_name = '''||table_name||'''';

    /*
     * On boucle sur toutes les clefs étrangères de la table d'origine pour mettre à jour les identifiants fournis en paramètre de la fonction
     */
	FOR foreign_key IN EXECUTE all_foreign_key_table
    LOOP
	    /*
	     * Remplacement des identifiants de la clef étrangère
	     */
        update_query := 'UPDATE '||foreign_key.referedschema||'.'||foreign_key.referredtable||' SET '||foreign_key.referredcolumn||' = '||new_id||' WHERE '||foreign_key.referredcolumn||' = '||old_id;
        BEGIN
            EXECUTE update_query;
           /*
            * Si tout se passe bien on continue l'exécution de boucle
            */
            EXCEPTION WHEN unique_violation THEN
        	/* Le code qui suit traite le cas des clefs composites et plus spécifiquement lorsque le remplacement des identifiants dans la table annexe conduit à une violation
        	 * de l'unicité de la clef primaire.
        	 * "pk_query" permet de rechercher tous les champs qui composent la clef primaire sur la table qui est traitée. Les champs obtenus par cette requête sont :
        	 * - primary_keys_table : un array de type texte correspondant à l'ensemble des champs composant la clef primaire
        	 * - select_query : une chaine de caractères listant tous les champs composant la clef primaire et pouvant être insérée dans une clause SELECT
        	 * - join_select_query : une chaine de caractères permettant de faire une autojointure sur la table traitée en fonction des clefs primaires de la table.
        	 * Le champ correspondant à l'identifiant qui doit être fusionné n'est pas pris en compte dans cette jointure.
        	 */
            RAISE NOTICE 'traitement de l''erreur' ;
            pk_query := 'SELECT string_agg(kcu.column_name::text, '',''), string_agg(''t1.''||kcu.column_name::text, '',''),
                        string_agg(case when c.is_nullable = ''YES'' then
                        ''COALESCE(t1.''||kcu.column_name::text||'',1) = COALESCE(t2.''||kcu.column_name::text || '',1)''
                        else ''t1.''||kcu.column_name::text||'' = t2.''||kcu.column_name::text end , '' AND '') FILTER (WHERE kcu.column_name <> '''||foreign_key.referredcolumn||''')
                    FROM information_schema.referential_constraints RC
                    INNER JOIN information_schema.key_column_usage AS KCU ON RC.constraint_name = KCU.constraint_name
                    LEFT JOIN information_schema.table_constraints AS TC ON TC.table_name = KCU.table_name AND KCU.table_schema = TC.table_schema
                left join INFORMATION_SCHEMA.COLUMNS c on TC.table_name = c.table_name AND TC.table_schema = c.table_schema AND kcu.column_name = c.column_name
                    WHERE TC.constraint_type = ''PRIMARY KEY'' AND KCU.table_schema = '''||foreign_key.referedschema||''' AND KCU.table_name = '''||foreign_key.referredtable||'''';
            EXECUTE pk_query INTO primary_keys_tables, select_query, join_select_query;

           /*
            * Récupération d'un unique enregistrement avec les valeurs possant problème et à supprimer pour pouvoir faire le remplacement des identifiants.
            * Cette requête est une auto-jointure sur la table comportant la clef étrangère en se servant du résultat de la précédente requête.
            * Le résultat est un JSON avec comme clef le nom du champ et comme valeur, la valeur du champ stockée sous forme de texte.
            */
            pk_query := 'SELECT json_object(''{'||primary_keys_tables||'}'', array['|| select_query ||']::text[]) json_value FROM '
                                        ||foreign_key.referedschema||'.'||foreign_key.referredtable||' t1 LEFT JOIN '
                                        ||foreign_key.referedschema||'.'||foreign_key.referredtable||
                                        ' t2 ON '||join_select_query||' WHERE t1.'||foreign_key.referredcolumn||' = '||old_id||
                                        ' AND t2.'||foreign_key.referredcolumn||' = '||new_id||' AND t2.'||
                                        foreign_key.referredcolumn||' IS NOT NULL';
            raise notice '%', pk_query;
            FOR record_delete IN EXECUTE pk_query
            LOOP
	            /*
	             * Dans cette boucle on traite le json créé précédement et on contruit la requête de suppression.
	             */
                delete_query := 'DELETE FROM '||foreign_key.referedschema||'.'||foreign_key.referredtable||' WHERE ';
                nb_iteration := 0;
                FOR val IN EXECUTE 'SELECT f.val, udt_name IN (''varchar'', ''text'') is_text
                                    FROM (SELECT regexp_split_to_table('''||primary_keys_tables||''','','') val) f
                                    LEFT JOIN information_schema.COLUMNS c ON c.column_name = f.val AND c.table_schema = '''||foreign_key.referedschema||'''
                                    AND c.table_name = '''||foreign_key.referredtable||''''  LOOP
                    /*
                        * Afin de construire la clause WHERE on boucle sur l'ensemble des champs composant la clef composite et on récupère le type de ceux-ci.
                        * Le compteur sur le nombre d'itérations permet de savoir si on rajoute un "AND".
                        */
                   IF nb_iteration > 0 THEN
                   	    delete_query := delete_query||' AND ';
                    END IF;
                   /*
                    * S'ils sont de type texte on rajoute des guillemets autour de la valeur, sinon on transforme la valeur en entier (int).
                    */
                    if ((record_delete.json_value)->>val.val) is null then
                        delete_query := delete_query||val.val||' is null';
                    elsIF  val.is_text THEN
                        delete_query := delete_query||val.val||' = '''||((record_delete.json_value)->>val.val)||'''' ;
                   ELSE
                   		delete_query := delete_query||val.val||' = '||((record_delete.json_value)->>val.val)::int;
                  END IF;
                    nb_iteration := nb_iteration+1;
                END LOOP;
                RAISE NOTICE '%', delete_query;
                EXECUTE delete_query;
            END LOOP;
           /*
            * On peut alors rejouer la requête de MAJ initiale.
            */
            EXECUTE update_query;
        END;
    END LOOP;
    RETURN 1;
END
$$ LANGUAGE plpgsql;


WITH org_update(org_id,uuid_actuel,uuid_national) AS ( values
    (429,'d1ab407b-9562-4919-82b4-54932c91260d'::uuid,'5A433BD0-2070-25D9-E053-2614A8C026F8'::uuid),
    (681,'222e7061-f8e5-4131-aa0e-daaa8a636c73'::uuid,'5A433BD0-203D-25D9-E053-2614A8C026F8'::uuid),
    (684,'46c918c4-997d-42ac-9c7a-349dc53d595d'::uuid,'5a433bd0-1ff6-25d9-e053-2614a8c026f8'::uuid),
    (394,'717695c8-ea2e-46bd-a9cd-ce20553d8f60'::uuid,'34BE1796-6774-49F6-A970-D62491078C40'::uuid),
    (711,'d9ec6e65-cc01-499e-adaa-be4b12c58a9f'::uuid,'c52a1bfa-4eaf-4c52-a923-3c59f4a81cc2'::uuid),
    (712,'dc1c176f-fdea-4cea-adb5-419f7a4bc7d3'::uuid,'5a433bd0-1ff0-25d9-e053-2614a8c026f8'::uuid),
    (699,'8bc6d56f-e014-4dd1-9155-7c16e8227c47'::uuid,'e62d0b50-aa93-4dc5-b1e9-a7cdbea355fd'::uuid),
    (412,'a71b97e1-5e6b-4e86-8a59-6454c63b709e'::uuid,'03d95b75-9fca-4a0b-97af-09c856c095e2'::uuid),
    (396,'7f0bc4a4-0a65-438c-9160-3519fce624ac'::uuid,'5188C32F-9B86-4636-AFC8-8DE0DE6B1AAC'::uuid),
    (450,'ef85d20b-5695-4aaf-a5a4-ed32ea5625f5'::uuid,'5fff41fa-903c-434b-affa-481f49316266'::uuid),
    (398,'80d6f9f4-7b64-476d-9863-2546ad1cee66'::uuid,'cad93628-e086-4b53-b46f-d3bad47e0317'::uuid),
    (415,'addf75b3-d0fc-4e91-ada1-ee535a4708ec'::uuid,'51F253DF-1B3B-4876-8F94-4FCB45E0FD3C'::uuid),
    (706,'afd689c8-dd67-453c-a0f0-b7c7b15a9cf2'::uuid,'5a433bd0-203f-25d9-e053-2614a8c026f8'::uuid),
    (357,'19d0c7b3-c68d-4422-b7a2-f4929825d862'::uuid,'FBA5FF98-13F4-4EED-88C0-D10F9ECB4C00'::uuid),
    (420,'bf62d090-fdc9-4e2e-a635-25eaca573057'::uuid,'6B5908E8-758F-4163-BE03-FF1655F553EB'::uuid),
    (385,'5a32e203-f3f3-4e48-ba85-d5763bc57dbe'::uuid,'60974406-ccc3-4010-9788-fa05789ca2eb'::uuid),
    (441,'e75178c1-ffbe-4cd4-9db8-bc94688a7127'::uuid,'4522E0BF-EE83-495B-89F7-F1A6128ADB61'::uuid),
    (384,'57f513b4-e997-4b41-b5fa-58c37d268648'::uuid,'27C60AE3-D841-4197-B21E-797894EA0835'::uuid),
    (418,'b24a9b1e-c363-4771-a8ee-d5381af85fb1'::uuid,'F0E41A26-F387-46AA-9C47-CA755798E911'::uuid),
    (369,'32569afb-fd06-454f-8568-2a18cb4cd454'::uuid,'DF588DCA-E0EF-4A91-8A02-0513FD5C5589'::uuid),
    (378,'3e8d85c0-9781-499b-8610-94c522a4484e'::uuid,'5f301924-f1e3-5da1-e053-2614a8c0f028'::uuid),
    (421,'c1a9ee8d-32ea-45c8-81b6-dd9decc13b5c'::uuid,'be01937b-239d-4f89-80bf-ea0fe258ddc7'::uuid),
    (436,'de31e0e6-dd95-42b2-b840-a1994761062e'::uuid,'FA436A3E-21A8-4FA1-B2E9-D117020B6641'::uuid),
    (370,'33b014f8-fb90-4a04-b532-cfa8febe29a4'::uuid,'BB15485B-256B-457E-9D77-0E2E4A37CD9C'::uuid),
    (348,'1149a98f-fe5d-4143-a71f-9adbf0ebf20a'::uuid,'5A433BD0-20AC-25D9-E053-2614A8C026F8'::uuid),
    (407,'9f65189d-b5cc-4a99-914b-059f80d6e1fa'::uuid,'5a433bd0-2082-25d9-e053-2614a8c026f8'::uuid),
    (361,'1f73fca7-41cc-4a94-a89e-a9edb7197abf'::uuid,'5a433bd0-1fec-25d9-e053-2614a8c026f8'::uuid),
    (366,'2851b49b-4e7b-425e-a277-83a3d5e8a959'::uuid,'5a433bd0-1fca-25d9-e053-2614a8c026f8'::uuid),
    (692,'7b84f7c5-fa93-47c4-ab1d-4bea7bf5880f'::uuid,'b7b0d9ca-7d9c-46c3-a64d-408008b1a25f'::uuid),
    (455,'fd6236fa-5c2c-48de-9080-c5253420c2ef'::uuid,'02da82b2-88b9-48fd-938b-574592e9c57b'::uuid),
    (413,'aa24930c-e888-45d9-8097-7e09de2c52ca'::uuid,'344F9BB6-686C-42BA-B6CA-6546F6586638'::uuid),
    (428,'d17899e8-41e5-4e0f-94d1-bd5b0de97d68'::uuid,'a14a142d-a3a3-126f-e053-2614a8c0cfbe'::uuid),
    (426,'cfebea5d-ef23-4abd-bdbb-8f47a42377ef'::uuid,'cb805dca-d267-49e8-8086-b1d45d4ff56d'::uuid),
    (432,'d8decea1-7704-40ec-98b7-00a8e8a749a8'::uuid,'71441dba-63c8-4d8e-adc6-63e3186355c6'::uuid),
    (362,'218ae540-9daa-464e-9f7d-78e84ebf2bad'::uuid,'853a5c59-1736-4a0d-81be-9cdcf04ced7a'::uuid),
    (437,'e1aa091f-67c2-4cae-a91d-0b5576d0526b'::uuid,'972e2407-7a25-4726-b89a-e09316cbacec'::uuid),
    (367,'2c631b51-6804-448c-852f-9e08587dfe15'::uuid,'5F832FC3-7E5D-3553-E053-2614A8C09903'::uuid),
    (410,'a2008389-fd20-41d3-98f1-dfdc61832770'::uuid,'7EDAE86B-829D-4A21-A8D6-E33D5C2DF4A0'::uuid),
    (688,'6520566e-7d7f-4086-a0e7-d72f1bfaa2bf'::uuid,'5A433BD0-207F-25D9-E053-2614A8C026F8'::uuid),
    (405,'9733af81-6558-4f75-8170-08319c4e95a9'::uuid,'5a433bd0-1ffc-25d9-e053-2614a8c026f8'::uuid),
    (414,'aa709fe8-ea57-4a56-b91c-615829e1ee8d'::uuid,'5A433BD0-2075-25D9-E053-2614A8C026F8'::uuid),
    (424,'cc41c772-eadc-4933-bf17-f86a8b748d5d'::uuid,'8CC5F9F6-F7FB-47A5-BE2D-6F08E57CCBB6'::uuid),
    (365,'26839a10-fc85-4033-99cc-6f3e6b5b1f9d'::uuid,'5a7c3409-1ddf-446b-b595-3677dd8d8971'::uuid),
    (375,'3b8cc2f1-60a8-4d22-ba39-6dd18bbfef8a'::uuid,'638d9475-ed22-4907-8a80-00777608b4b5'::uuid),
    (353,'14c5900f-8c17-4487-9cf5-70f0b3cf0699'::uuid,'689C3B02-B063-493F-8E81-2DD774FA199A'::uuid),
    (707,'b4e2e601-e95c-4b85-97b1-1582d8e6e5ca'::uuid,'8f86a944-5f80-11ed-8ce0-005056aa3715'::uuid),
    (400,'8a2a3558-5150-41a0-b850-0802e5c3e392'::uuid,'aaa5029c-fced-6be5-e053-2614a8c07765'::uuid),
    (435,'dbfb5e0c-ded2-4b3c-947f-5b59a03c8b09'::uuid,'f4fd202a-88a7-45d3-9f63-d0cc6ee059e7'::uuid),
    (425,'ce65ba3c-7e96-4d95-a767-de20b909a3bf'::uuid,'416C4A2C-7837-404D-A944-9C01CCDE3C4C'::uuid),
    (346,'0fa886eb-44f0-46ed-9664-abd41bddd7ef'::uuid,'5A433BD0-2001-25D9-E053-2614A8C026F8'::uuid),
    (402,'8c392909-5a38-4c70-9fc7-20c252aeb93b'::uuid,'92E950C4-0D5F-4EB1-B010-FFF810E5E567'::uuid),
    (704,'a92b5aae-5295-4ac8-b152-898bf42e7121'::uuid,'14ba96b3-775a-445f-ae8c-a85a00a01835'::uuid),
    (709,'c884d7da-a392-4b90-b1c6-f8d99904a42e'::uuid,'6B0968A2-EED3-4478-994D-DAF5E70AEB7C'::uuid),
    (419,'b5e81f7f-5518-4c68-a52a-732e68e74298'::uuid,'6a602a9b-9acb-4787-aac6-a7e822c97afe'::uuid),
    (372,'383fe453-da10-4c04-87a1-54182e69d714'::uuid,'E29A95FA-38D8-41FF-A8F7-420370699296'::uuid),
    (694,'82568af7-b02a-437f-9ff6-dbb0f4ad0330'::uuid,'AC4C9551-6D4B-477E-A480-C7597EADDAE3'::uuid),
    (440,'e70e529d-049a-4980-a9ad-097f323a9617'::uuid,'847E212C-3169-4812-BB18-E1232F05F71E'::uuid),
    (452,'f177720b-f87c-48f0-aee2-4d3bf282925c'::uuid,'DE311BA3-113A-4071-8E1E-34B6D6597E56'::uuid),
    (356,'1824e8df-3cfc-4130-ac32-53185e1573b9'::uuid,'25F4695B-A911-49CE-88EC-D58E45DC3648'::uuid),
    (340,'04e0816c-817f-4278-a319-eee51bf6adfe'::uuid,'A48CC8DF-755A-4C7B-9BAA-328E26BEA1A8'::uuid),
    (685,'59a46960-3ef2-4bdd-b3d4-99a514beaad5'::uuid,'5be405eb-6de7-48b8-87f3-96c3d02badee'::uuid),
    (687,'63fd0fc3-c537-4f54-b891-35ad345c2f00'::uuid,'6d5d581c-eb0b-11eb-99fb-005056aa3715'::uuid),
    (689,'69625913-09c8-4aff-a014-c011f994b0b5'::uuid,'ED29A998-B8E0-4F01-BD46-D5475F81ACE1'::uuid),
    (392,'6eb571ba-4e22-4cfe-9064-5873ae7a2ca9'::uuid,'47607BAF-43D2-4FC8-AFA9-A38935FD1F9B'::uuid),
    (710,'ce4782c6-9cf3-47a1-8460-26b3a1de7b68'::uuid,'5A433BD0-20C1-25D9-E053-2614A8C026F8'::uuid),
    (693,'81a8e8f4-b797-4a1b-99f2-d8d21647c639'::uuid,'538b95ed-e51b-4b55-b9aa-4f94c5bf955a'::uuid),
    (430,'d323b7fc-74cb-4389-9b7d-845ae1d8430f'::uuid,'0cab1cdd-f78a-4541-af40-0937fe6cd1fd'::uuid),
    (673,'0209d734-15db-4579-841d-dcb18305c512'::uuid,'5f301924-f1ea-5da1-e053-2614a8c0f028'::uuid),
    (423,'c90e7d50-cf52-494e-b11a-4d0412fed785'::uuid,'5A433BD0-2023-25D9-E053-2614A8C026F8'::uuid),
    (364,'26730af1-bdfe-4626-970c-713621323cd8'::uuid,'5A433BD0-1F9E-25D9-E053-2614A8C026F8'::uuid),
    (703,'9e96d3fd-1e4e-445d-9749-418bb43052ac'::uuid,'E7523F23-D7BB-4790-B02E-C93408915096'::uuid),
    (379,'3fa4bc55-3b0a-4eb6-a26f-6c44ec00761a'::uuid,'887AE811-4A08-422B-B57D-C3B3D62CCF9C'::uuid),
    (718,'fbf2d73a-364c-4447-a343-54b87f25174d'::uuid,'5c4b022a-17fc-6f1e-e053-2614a8c09d9f'::uuid),
    (701,'90bf40dd-eeb6-4d00-93e7-fef579278507'::uuid,'5c4b022a-17fa-6f1e-e053-2614a8c09d9f'::uuid),
    (376,'3d29214d-b37a-41f4-b9e3-92c4836e9d21'::uuid,'CD4BCC9A-C424-461C-8B1A-1FABB62C77B6'::uuid),
    (417,'b0a9e18a-74d9-413d-81a3-a8693e0d0d6d'::uuid,'6d5da3b2-eb0b-11eb-99fb-005056aa3715'::uuid),
    (680,'2031aab3-1906-4f6f-9fd1-78099ad97c45'::uuid,'07503468-747d-4a0d-932e-a235c4ff92e5'::uuid),
    (683,'3bc68c54-f139-4233-89bf-9ae05633393b'::uuid,'edaed580-faac-11eb-8fd1-005056aa3715'::uuid),
    (716,'f6c03e2c-a2bf-44f2-9fe3-a6476139d589'::uuid,'62f6dc18-1b68-0553-e053-2614a8c052d6'::uuid),
    (679,'1a5ef5b6-723a-4d51-84e9-74ba997e6975'::uuid,'62cda494-5a14-44e1-e053-2614a8c0faa0'::uuid),
    (691,'73404155-c001-4975-b8b4-76dea744f468'::uuid,'5f832fc3-7e57-3553-e053-2614a8c09903'::uuid),
    (708,'c2d0c201-3092-4aba-bf29-8c5705e07166'::uuid,'5a433bd0-1fc9-25d9-e053-2614a8c026f8'::uuid),
    (401,'8b94efcf-9baa-4520-b7a7-8ab403ece43b'::uuid,'5A433BD0-20E5-25D9-E053-2614A8C026F8'::uuid),
    (453,'f2c26e61-9f14-4317-b3f2-6290a98911ad'::uuid,'5F301924-F1E0-5DA1-E053-2614A8C0F028'::uuid),
    (397,'803aefa5-c808-4b90-9dcb-34a2ee3292c1'::uuid,'0f5f0847-25f2-40f0-9e26-26fdb4515dd4'::uuid),
    (447,'edd1ab04-000e-4991-bd39-c34f7597347b'::uuid,'5A433BD0-211B-25D9-E053-2614A8C026F8'::uuid),
    (386,'5c54824f-6738-4fa9-ba96-e719e05e87e7'::uuid,'5A433BD0-20EB-25D9-E053-2614A8C026F8'::uuid),
    (714,'f0b02fc7-6453-4351-980f-8b5261a741db'::uuid,'88B60578-0CC0-4432-93C8-231FB1436E15'::uuid),
    (408,'a18c896e-4792-4499-a279-6b99c5650979'::uuid,'42FE4D19-BED4-4F90-8272-012F4A3C0E8F'::uuid),
    (363,'23c32fc4-6118-488c-b535-26e3872228b9'::uuid,'F2B505AE-78AB-43DE-97C5-3466B1787343'::uuid),
    (434,'dbe81ab8-3185-4203-a619-7fd1d7ff9980'::uuid,'184F1587-DF3B-41F3-A41A-3DD5DD9A8DD9'::uuid),
    (431,'d536db84-73de-43c7-b542-e7071afa043a'::uuid,'DF75D4E0-52BD-4084-BA76-16B4C4ABEB16'::uuid),
    (444,'ea5abf46-2243-46ca-8fdc-887ddd8fc186'::uuid,'C5666F02-121E-41A5-B07C-629BE127FDBE'::uuid),
    (406,'9b689d63-e2f2-4224-a67c-8cdb69e76c13'::uuid,'EB4640EE-DEED-42B2-B0DF-383120A5DE00'::uuid),
    (360,'1df14810-809f-4c15-a45c-76e41cb50e98'::uuid,'E36DB09A-8E53-48AF-BBC6-D1FBF2E10EA7'::uuid),
    (715,'f325afd4-d4de-42de-ae0d-c8d8b2d5345c'::uuid,'120B37F8-E1EC-4B9C-85E0-E6703D71007C'::uuid),
    (682,'25af5663-62c3-4aee-92db-843b4131fcaa'::uuid,'76EB9FAA-4F63-49FB-885D-12D98577CA57'::uuid),
    (358,'1a6e1bd8-9944-4678-ad37-a12ec0d75055'::uuid,'595D5866-6934-4B91-B914-0264652F7D22'::uuid),
    (374,'3b68bd85-520f-4fc4-9c55-4f3ca54c6890'::uuid,'5A433BD0-20C2-25D9-E053-2614A8C026F8'::uuid),
    (449,'ef46c836-d61b-4d3b-9a60-f351d8172a56'::uuid,'5A433BD0-2020-25D9-E053-2614A8C026F8'::uuid),
    (427,'d07030d4-b2ea-49c8-a567-9006b9b083af'::uuid,'5A433BD0-206B-25D9-E053-2614A8C026F8'::uuid),
    (351,'131ec1e3-1029-408e-9202-54a5f0833de2'::uuid,'152d82a6-c214-4505-bffa-bec8d21063f8'::uuid),
    (702,'9437d35f-041b-4ff3-acc1-4c69209c614c'::uuid,'5a433bd0-1fbe-25d9-e053-2614a8c026f8'::uuid),
    (676,'06e007af-83d2-4c4a-af21-df1cb9a504a9'::uuid,'5bd3e675-aa1c-2ebb-e053-2614a8c0cdc5'::uuid),
    (675,'043d8ec7-0bbd-43b9-9f59-2dbd24c0772a'::uuid,'260b013d-fa82-46d5-9676-9538f891dee7'::uuid),
    (381,'47830764-c4cf-4c83-b77a-d7cbb92abade'::uuid,'7203C77B-8680-468F-84D7-FCB0926AB3F3'::uuid),
    (359,'1bb0851a-605f-4d55-b0b4-c11ee016ccc4'::uuid,'279FD94E-9B74-47F8-A6FD-C7F4C84F3AF4'::uuid),
    (399,'86ea1b20-b270-4bc3-825f-fd1351ad4e50'::uuid,'45cf5f28-7f7f-41ca-ac6d-03c75432fe3d'::uuid),
    (341,'04fda009-315e-4c14-adfc-d63a10a43f87'::uuid,'952E50A9-7CEC-4D26-B412-91BCE6112A52'::uuid),
    (422,'c4658881-29ab-418a-9539-62b24314c38f'::uuid,'7C774022-343C-4D36-AA20-1517F1563B1A'::uuid),
    (377,'3e362dc9-fecc-49a1-896d-51941f99df5f'::uuid,'320bc56c-c927-4464-8f05-c2b14b3d13b4'::uuid),
    (382,'4b897049-a89e-41dc-b62d-64b7c109bb12'::uuid,'AD0F50A5-704D-470B-B79E-C1CB381FC0D1'::uuid),
    (672,'005633f5-73a7-42aa-a20a-d0ac55a554d6'::uuid,'F9736185-3E68-40CA-BD23-639424399161'::uuid)
),
org_id_to_delete AS (
    SELECT  merge_id('utilisateurs', 'bib_organismes', o.org_id, id_organisme), *
    FROM utilisateurs.bib_organismes bo
        INNER JOIN org_update  o
            ON bo.uuid_organisme = o.uuid_national
)
DELETE FROM utilisateurs.bib_organismes
WHERE id_organisme IN (SELECT org_id FROM org_id_to_delete);
-- 54 lignes supprimées


WITH org_update(org_id,uuid_actuel,uuid_national) AS ( values
    (429,'d1ab407b-9562-4919-82b4-54932c91260d'::uuid,'5A433BD0-2070-25D9-E053-2614A8C026F8'::uuid),
    (681,'222e7061-f8e5-4131-aa0e-daaa8a636c73'::uuid,'5A433BD0-203D-25D9-E053-2614A8C026F8'::uuid),
    (684,'46c918c4-997d-42ac-9c7a-349dc53d595d'::uuid,'5a433bd0-1ff6-25d9-e053-2614a8c026f8'::uuid),
    (394,'717695c8-ea2e-46bd-a9cd-ce20553d8f60'::uuid,'34BE1796-6774-49F6-A970-D62491078C40'::uuid),
    (711,'d9ec6e65-cc01-499e-adaa-be4b12c58a9f'::uuid,'c52a1bfa-4eaf-4c52-a923-3c59f4a81cc2'::uuid),
    (712,'dc1c176f-fdea-4cea-adb5-419f7a4bc7d3'::uuid,'5a433bd0-1ff0-25d9-e053-2614a8c026f8'::uuid),
    (699,'8bc6d56f-e014-4dd1-9155-7c16e8227c47'::uuid,'e62d0b50-aa93-4dc5-b1e9-a7cdbea355fd'::uuid),
    (412,'a71b97e1-5e6b-4e86-8a59-6454c63b709e'::uuid,'03d95b75-9fca-4a0b-97af-09c856c095e2'::uuid),
    (396,'7f0bc4a4-0a65-438c-9160-3519fce624ac'::uuid,'5188C32F-9B86-4636-AFC8-8DE0DE6B1AAC'::uuid),
    (450,'ef85d20b-5695-4aaf-a5a4-ed32ea5625f5'::uuid,'5fff41fa-903c-434b-affa-481f49316266'::uuid),
    (398,'80d6f9f4-7b64-476d-9863-2546ad1cee66'::uuid,'cad93628-e086-4b53-b46f-d3bad47e0317'::uuid),
    (415,'addf75b3-d0fc-4e91-ada1-ee535a4708ec'::uuid,'51F253DF-1B3B-4876-8F94-4FCB45E0FD3C'::uuid),
    (706,'afd689c8-dd67-453c-a0f0-b7c7b15a9cf2'::uuid,'5a433bd0-203f-25d9-e053-2614a8c026f8'::uuid),
    (357,'19d0c7b3-c68d-4422-b7a2-f4929825d862'::uuid,'FBA5FF98-13F4-4EED-88C0-D10F9ECB4C00'::uuid),
    (420,'bf62d090-fdc9-4e2e-a635-25eaca573057'::uuid,'6B5908E8-758F-4163-BE03-FF1655F553EB'::uuid),
    (385,'5a32e203-f3f3-4e48-ba85-d5763bc57dbe'::uuid,'60974406-ccc3-4010-9788-fa05789ca2eb'::uuid),
    (441,'e75178c1-ffbe-4cd4-9db8-bc94688a7127'::uuid,'4522E0BF-EE83-495B-89F7-F1A6128ADB61'::uuid),
    (384,'57f513b4-e997-4b41-b5fa-58c37d268648'::uuid,'27C60AE3-D841-4197-B21E-797894EA0835'::uuid),
    (418,'b24a9b1e-c363-4771-a8ee-d5381af85fb1'::uuid,'F0E41A26-F387-46AA-9C47-CA755798E911'::uuid),
    (369,'32569afb-fd06-454f-8568-2a18cb4cd454'::uuid,'DF588DCA-E0EF-4A91-8A02-0513FD5C5589'::uuid),
    (378,'3e8d85c0-9781-499b-8610-94c522a4484e'::uuid,'5f301924-f1e3-5da1-e053-2614a8c0f028'::uuid),
    (421,'c1a9ee8d-32ea-45c8-81b6-dd9decc13b5c'::uuid,'be01937b-239d-4f89-80bf-ea0fe258ddc7'::uuid),
    (436,'de31e0e6-dd95-42b2-b840-a1994761062e'::uuid,'FA436A3E-21A8-4FA1-B2E9-D117020B6641'::uuid),
    (370,'33b014f8-fb90-4a04-b532-cfa8febe29a4'::uuid,'BB15485B-256B-457E-9D77-0E2E4A37CD9C'::uuid),
    (348,'1149a98f-fe5d-4143-a71f-9adbf0ebf20a'::uuid,'5A433BD0-20AC-25D9-E053-2614A8C026F8'::uuid),
    (407,'9f65189d-b5cc-4a99-914b-059f80d6e1fa'::uuid,'5a433bd0-2082-25d9-e053-2614a8c026f8'::uuid),
    (361,'1f73fca7-41cc-4a94-a89e-a9edb7197abf'::uuid,'5a433bd0-1fec-25d9-e053-2614a8c026f8'::uuid),
    (366,'2851b49b-4e7b-425e-a277-83a3d5e8a959'::uuid,'5a433bd0-1fca-25d9-e053-2614a8c026f8'::uuid),
    (692,'7b84f7c5-fa93-47c4-ab1d-4bea7bf5880f'::uuid,'b7b0d9ca-7d9c-46c3-a64d-408008b1a25f'::uuid),
    (455,'fd6236fa-5c2c-48de-9080-c5253420c2ef'::uuid,'02da82b2-88b9-48fd-938b-574592e9c57b'::uuid),
    (413,'aa24930c-e888-45d9-8097-7e09de2c52ca'::uuid,'344F9BB6-686C-42BA-B6CA-6546F6586638'::uuid),
    (428,'d17899e8-41e5-4e0f-94d1-bd5b0de97d68'::uuid,'a14a142d-a3a3-126f-e053-2614a8c0cfbe'::uuid),
    (426,'cfebea5d-ef23-4abd-bdbb-8f47a42377ef'::uuid,'cb805dca-d267-49e8-8086-b1d45d4ff56d'::uuid),
    (432,'d8decea1-7704-40ec-98b7-00a8e8a749a8'::uuid,'71441dba-63c8-4d8e-adc6-63e3186355c6'::uuid),
    (362,'218ae540-9daa-464e-9f7d-78e84ebf2bad'::uuid,'853a5c59-1736-4a0d-81be-9cdcf04ced7a'::uuid),
    (437,'e1aa091f-67c2-4cae-a91d-0b5576d0526b'::uuid,'972e2407-7a25-4726-b89a-e09316cbacec'::uuid),
    (367,'2c631b51-6804-448c-852f-9e08587dfe15'::uuid,'5F832FC3-7E5D-3553-E053-2614A8C09903'::uuid),
    (410,'a2008389-fd20-41d3-98f1-dfdc61832770'::uuid,'7EDAE86B-829D-4A21-A8D6-E33D5C2DF4A0'::uuid),
    (688,'6520566e-7d7f-4086-a0e7-d72f1bfaa2bf'::uuid,'5A433BD0-207F-25D9-E053-2614A8C026F8'::uuid),
    (405,'9733af81-6558-4f75-8170-08319c4e95a9'::uuid,'5a433bd0-1ffc-25d9-e053-2614a8c026f8'::uuid),
    (414,'aa709fe8-ea57-4a56-b91c-615829e1ee8d'::uuid,'5A433BD0-2075-25D9-E053-2614A8C026F8'::uuid),
    (424,'cc41c772-eadc-4933-bf17-f86a8b748d5d'::uuid,'8CC5F9F6-F7FB-47A5-BE2D-6F08E57CCBB6'::uuid),
    (365,'26839a10-fc85-4033-99cc-6f3e6b5b1f9d'::uuid,'5a7c3409-1ddf-446b-b595-3677dd8d8971'::uuid),
    (375,'3b8cc2f1-60a8-4d22-ba39-6dd18bbfef8a'::uuid,'638d9475-ed22-4907-8a80-00777608b4b5'::uuid),
    (353,'14c5900f-8c17-4487-9cf5-70f0b3cf0699'::uuid,'689C3B02-B063-493F-8E81-2DD774FA199A'::uuid),
    (707,'b4e2e601-e95c-4b85-97b1-1582d8e6e5ca'::uuid,'8f86a944-5f80-11ed-8ce0-005056aa3715'::uuid),
    (400,'8a2a3558-5150-41a0-b850-0802e5c3e392'::uuid,'aaa5029c-fced-6be5-e053-2614a8c07765'::uuid),
    (435,'dbfb5e0c-ded2-4b3c-947f-5b59a03c8b09'::uuid,'f4fd202a-88a7-45d3-9f63-d0cc6ee059e7'::uuid),
    (425,'ce65ba3c-7e96-4d95-a767-de20b909a3bf'::uuid,'416C4A2C-7837-404D-A944-9C01CCDE3C4C'::uuid),
    (346,'0fa886eb-44f0-46ed-9664-abd41bddd7ef'::uuid,'5A433BD0-2001-25D9-E053-2614A8C026F8'::uuid),
    (402,'8c392909-5a38-4c70-9fc7-20c252aeb93b'::uuid,'92E950C4-0D5F-4EB1-B010-FFF810E5E567'::uuid),
    (704,'a92b5aae-5295-4ac8-b152-898bf42e7121'::uuid,'14ba96b3-775a-445f-ae8c-a85a00a01835'::uuid),
    (709,'c884d7da-a392-4b90-b1c6-f8d99904a42e'::uuid,'6B0968A2-EED3-4478-994D-DAF5E70AEB7C'::uuid),
    (419,'b5e81f7f-5518-4c68-a52a-732e68e74298'::uuid,'6a602a9b-9acb-4787-aac6-a7e822c97afe'::uuid),
    (372,'383fe453-da10-4c04-87a1-54182e69d714'::uuid,'E29A95FA-38D8-41FF-A8F7-420370699296'::uuid),
    (694,'82568af7-b02a-437f-9ff6-dbb0f4ad0330'::uuid,'AC4C9551-6D4B-477E-A480-C7597EADDAE3'::uuid),
    (440,'e70e529d-049a-4980-a9ad-097f323a9617'::uuid,'847E212C-3169-4812-BB18-E1232F05F71E'::uuid),
    (452,'f177720b-f87c-48f0-aee2-4d3bf282925c'::uuid,'DE311BA3-113A-4071-8E1E-34B6D6597E56'::uuid),
    (356,'1824e8df-3cfc-4130-ac32-53185e1573b9'::uuid,'25F4695B-A911-49CE-88EC-D58E45DC3648'::uuid),
    (340,'04e0816c-817f-4278-a319-eee51bf6adfe'::uuid,'A48CC8DF-755A-4C7B-9BAA-328E26BEA1A8'::uuid),
    (685,'59a46960-3ef2-4bdd-b3d4-99a514beaad5'::uuid,'5be405eb-6de7-48b8-87f3-96c3d02badee'::uuid),
    (687,'63fd0fc3-c537-4f54-b891-35ad345c2f00'::uuid,'6d5d581c-eb0b-11eb-99fb-005056aa3715'::uuid),
    (689,'69625913-09c8-4aff-a014-c011f994b0b5'::uuid,'ED29A998-B8E0-4F01-BD46-D5475F81ACE1'::uuid),
    (392,'6eb571ba-4e22-4cfe-9064-5873ae7a2ca9'::uuid,'47607BAF-43D2-4FC8-AFA9-A38935FD1F9B'::uuid),
    (710,'ce4782c6-9cf3-47a1-8460-26b3a1de7b68'::uuid,'5A433BD0-20C1-25D9-E053-2614A8C026F8'::uuid),
    (693,'81a8e8f4-b797-4a1b-99f2-d8d21647c639'::uuid,'538b95ed-e51b-4b55-b9aa-4f94c5bf955a'::uuid),
    (430,'d323b7fc-74cb-4389-9b7d-845ae1d8430f'::uuid,'0cab1cdd-f78a-4541-af40-0937fe6cd1fd'::uuid),
    (673,'0209d734-15db-4579-841d-dcb18305c512'::uuid,'5f301924-f1ea-5da1-e053-2614a8c0f028'::uuid),
    (423,'c90e7d50-cf52-494e-b11a-4d0412fed785'::uuid,'5A433BD0-2023-25D9-E053-2614A8C026F8'::uuid),
    (364,'26730af1-bdfe-4626-970c-713621323cd8'::uuid,'5A433BD0-1F9E-25D9-E053-2614A8C026F8'::uuid),
    (703,'9e96d3fd-1e4e-445d-9749-418bb43052ac'::uuid,'E7523F23-D7BB-4790-B02E-C93408915096'::uuid),
    (379,'3fa4bc55-3b0a-4eb6-a26f-6c44ec00761a'::uuid,'887AE811-4A08-422B-B57D-C3B3D62CCF9C'::uuid),
    (718,'fbf2d73a-364c-4447-a343-54b87f25174d'::uuid,'5c4b022a-17fc-6f1e-e053-2614a8c09d9f'::uuid),
    (701,'90bf40dd-eeb6-4d00-93e7-fef579278507'::uuid,'5c4b022a-17fa-6f1e-e053-2614a8c09d9f'::uuid),
    (376,'3d29214d-b37a-41f4-b9e3-92c4836e9d21'::uuid,'CD4BCC9A-C424-461C-8B1A-1FABB62C77B6'::uuid),
    (417,'b0a9e18a-74d9-413d-81a3-a8693e0d0d6d'::uuid,'6d5da3b2-eb0b-11eb-99fb-005056aa3715'::uuid),
    (680,'2031aab3-1906-4f6f-9fd1-78099ad97c45'::uuid,'07503468-747d-4a0d-932e-a235c4ff92e5'::uuid),
    (683,'3bc68c54-f139-4233-89bf-9ae05633393b'::uuid,'edaed580-faac-11eb-8fd1-005056aa3715'::uuid),
    (716,'f6c03e2c-a2bf-44f2-9fe3-a6476139d589'::uuid,'62f6dc18-1b68-0553-e053-2614a8c052d6'::uuid),
    (679,'1a5ef5b6-723a-4d51-84e9-74ba997e6975'::uuid,'62cda494-5a14-44e1-e053-2614a8c0faa0'::uuid),
    (691,'73404155-c001-4975-b8b4-76dea744f468'::uuid,'5f832fc3-7e57-3553-e053-2614a8c09903'::uuid),
    (708,'c2d0c201-3092-4aba-bf29-8c5705e07166'::uuid,'5a433bd0-1fc9-25d9-e053-2614a8c026f8'::uuid),
    (401,'8b94efcf-9baa-4520-b7a7-8ab403ece43b'::uuid,'5A433BD0-20E5-25D9-E053-2614A8C026F8'::uuid),
    (453,'f2c26e61-9f14-4317-b3f2-6290a98911ad'::uuid,'5F301924-F1E0-5DA1-E053-2614A8C0F028'::uuid),
    (397,'803aefa5-c808-4b90-9dcb-34a2ee3292c1'::uuid,'0f5f0847-25f2-40f0-9e26-26fdb4515dd4'::uuid),
    (447,'edd1ab04-000e-4991-bd39-c34f7597347b'::uuid,'5A433BD0-211B-25D9-E053-2614A8C026F8'::uuid),
    (386,'5c54824f-6738-4fa9-ba96-e719e05e87e7'::uuid,'5A433BD0-20EB-25D9-E053-2614A8C026F8'::uuid),
    (714,'f0b02fc7-6453-4351-980f-8b5261a741db'::uuid,'88B60578-0CC0-4432-93C8-231FB1436E15'::uuid),
    (408,'a18c896e-4792-4499-a279-6b99c5650979'::uuid,'42FE4D19-BED4-4F90-8272-012F4A3C0E8F'::uuid),
    (363,'23c32fc4-6118-488c-b535-26e3872228b9'::uuid,'F2B505AE-78AB-43DE-97C5-3466B1787343'::uuid),
    (434,'dbe81ab8-3185-4203-a619-7fd1d7ff9980'::uuid,'184F1587-DF3B-41F3-A41A-3DD5DD9A8DD9'::uuid),
    (431,'d536db84-73de-43c7-b542-e7071afa043a'::uuid,'DF75D4E0-52BD-4084-BA76-16B4C4ABEB16'::uuid),
    (444,'ea5abf46-2243-46ca-8fdc-887ddd8fc186'::uuid,'C5666F02-121E-41A5-B07C-629BE127FDBE'::uuid),
    (406,'9b689d63-e2f2-4224-a67c-8cdb69e76c13'::uuid,'EB4640EE-DEED-42B2-B0DF-383120A5DE00'::uuid),
    (360,'1df14810-809f-4c15-a45c-76e41cb50e98'::uuid,'E36DB09A-8E53-48AF-BBC6-D1FBF2E10EA7'::uuid),
    (715,'f325afd4-d4de-42de-ae0d-c8d8b2d5345c'::uuid,'120B37F8-E1EC-4B9C-85E0-E6703D71007C'::uuid),
    (682,'25af5663-62c3-4aee-92db-843b4131fcaa'::uuid,'76EB9FAA-4F63-49FB-885D-12D98577CA57'::uuid),
    (358,'1a6e1bd8-9944-4678-ad37-a12ec0d75055'::uuid,'595D5866-6934-4B91-B914-0264652F7D22'::uuid),
    (374,'3b68bd85-520f-4fc4-9c55-4f3ca54c6890'::uuid,'5A433BD0-20C2-25D9-E053-2614A8C026F8'::uuid),
    (449,'ef46c836-d61b-4d3b-9a60-f351d8172a56'::uuid,'5A433BD0-2020-25D9-E053-2614A8C026F8'::uuid),
    (427,'d07030d4-b2ea-49c8-a567-9006b9b083af'::uuid,'5A433BD0-206B-25D9-E053-2614A8C026F8'::uuid),
    (351,'131ec1e3-1029-408e-9202-54a5f0833de2'::uuid,'152d82a6-c214-4505-bffa-bec8d21063f8'::uuid),
    (702,'9437d35f-041b-4ff3-acc1-4c69209c614c'::uuid,'5a433bd0-1fbe-25d9-e053-2614a8c026f8'::uuid),
    (676,'06e007af-83d2-4c4a-af21-df1cb9a504a9'::uuid,'5bd3e675-aa1c-2ebb-e053-2614a8c0cdc5'::uuid),
    (675,'043d8ec7-0bbd-43b9-9f59-2dbd24c0772a'::uuid,'260b013d-fa82-46d5-9676-9538f891dee7'::uuid),
    (381,'47830764-c4cf-4c83-b77a-d7cbb92abade'::uuid,'7203C77B-8680-468F-84D7-FCB0926AB3F3'::uuid),
    (359,'1bb0851a-605f-4d55-b0b4-c11ee016ccc4'::uuid,'279FD94E-9B74-47F8-A6FD-C7F4C84F3AF4'::uuid),
    (399,'86ea1b20-b270-4bc3-825f-fd1351ad4e50'::uuid,'45cf5f28-7f7f-41ca-ac6d-03c75432fe3d'::uuid),
    (341,'04fda009-315e-4c14-adfc-d63a10a43f87'::uuid,'952E50A9-7CEC-4D26-B412-91BCE6112A52'::uuid),
    (422,'c4658881-29ab-418a-9539-62b24314c38f'::uuid,'7C774022-343C-4D36-AA20-1517F1563B1A'::uuid),
    (377,'3e362dc9-fecc-49a1-896d-51941f99df5f'::uuid,'320bc56c-c927-4464-8f05-c2b14b3d13b4'::uuid),
    (382,'4b897049-a89e-41dc-b62d-64b7c109bb12'::uuid,'AD0F50A5-704D-470B-B79E-C1CB381FC0D1'::uuid),
    (672,'005633f5-73a7-42aa-a20a-d0ac55a554d6'::uuid,'F9736185-3E68-40CA-BD23-639424399161'::uuid) )
UPDATE utilisateurs.bib_organismes bo
SET uuid_organisme = uo.uuid_national
FROM org_update uo
WHERE bo.id_organisme = uo.org_id ;
-- 59 lignes mise à jour

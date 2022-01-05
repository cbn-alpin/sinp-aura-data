-- Query to extracts taxon status for Savoie ENS
-- Usage (from local computer): cat ./ens_savoie_status.sql | ssh <user>@<ip-server> 'export PGPASSWORD="<db-user-password>" ; psql -h localhost -p <db-port> -U <db-user> -d <db-name>' > ./$(date +'%F')_extracts_status.csv
-- The CSV file should contain 20,762 lines.
COPY (
  WITH TAXA_IN_SAVOIE AS (
      SELECT DISTINCT t.cd_ref
      FROM gn_synthese.synthese s
          JOIN gn_synthese.cor_area_synthese AS a
              ON s.id_synthese = a.id_synthese
          JOIN taxonomie.taxref as t
              ON s.cd_nom = t.cd_nom
      WHERE a.id_area = (SELECT id_area FROM ref_geo.l_areas WHERE area_code = 'SAVOIE')
  )
  SELECT 
    s.cd_ref,
    t.nom_valide,
    t.nom_vern,
    t.group1_inpn,
    t.group2_inpn,
    s.cd_type_statut,
    s.lb_type_statut,
    s.regroupement_type,
    s.code_statut,
    s.label_statut,
    s.rq_statut,
    s.cd_sig,
    s.cd_doc,
    s.lb_adm_tr,
    s.niveau_admin,
    s.full_citation,
    s.doc_url
  FROM taxonomie.taxref_bdc_statut AS s
    JOIN taxonomie.taxref AS t
      ON s.cd_ref = t.cd_nom
  WHERE s.cd_nom IN (SELECT cd_ref FROM TAXA_IN_SAVOIE)
    AND (
    s.lb_adm_tr IN ('France','France métropolitaine', 'Rhône-Alpes','Savoie') 
    OR s.cd_doc IN (264873, 264875)
  )
) TO stdout
WITH (format csv, header, delimiter E'\t');

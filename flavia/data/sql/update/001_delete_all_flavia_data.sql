-- Suppression de toutes les données de la LPO + l'utilisateur importé lors de
-- la transmission de données de 2021.
-- Si la table `gn2pg_flavia.data_json` existe, les triggers sont déclenchés.
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/lpo/data/sql/update/001_*

BEGIN ;

CREATE TEMPORARY TABLE delete_roles (
    role_uuid uuid,
    PRIMARY KEY (role_uuid)
) ;
INSERT INTO delete_roles (role_uuid) VALUES
    ('8f6f554b-740a-4ed4-9c3a-573af9e8b229'),
    ('f8a6ed55-f213-4d00-83e1-9bc30134a59b'),
    ('b6471b70-6d0c-4dc7-aac9-bb690b6969d4'),
    ('3fcf13a1-2357-4945-8358-de052c096bc6'),
    ('b80070b3-fd60-42bd-a987-98b99f1f77bf'),
    ('904090dd-ae8e-430e-9692-88b4b2ec1de0'),
    ('2a254974-f446-4c44-b163-dbf83516e345'),
    ('bf19788f-5679-47cc-8ea7-444f2d71343b'),
    ('f96cb1e7-0073-48a2-8113-9aca10fd9d78'),
    ('f01bf666-4296-4a1e-b713-6740c91b62a7'),
    ('0081e92c-3b38-4417-9dcb-6dd7c5d4c904'),
    ('c46a071d-38be-4066-96b4-2ff4a8c2368b'),
    ('d7a5b6a1-df80-4b41-8a26-28a5f7c7a7a8'),
    ('d6ef6158-ffb0-404d-9f00-007e9e3a4b8d'),
    ('d00d8dc0-639c-47b4-b41a-07af6b77f474'),
    ('39dd0762-a124-4cad-aff9-939722e2a124'),
    ('a0046d4b-d60e-42ac-aa0b-ea40e873f790'),
    ('c65e5681-22c9-4f90-938b-97541d72843a'),
    ('216b646f-b537-4de3-b93b-98105412962b'),
    ('205da6de-6d38-4851-a0e0-8b25cad4090a'),
    ('b5d6a136-3a97-48e6-b790-862d49b7611d'),
    ('03412507-9d66-4fa0-bbf3-a9459b5af496'),
    ('0ceb523a-c017-4186-8a2a-12f8f81cfdf9'),
    ('f758de7d-ac00-4929-8c1f-4026a0e0ab12'),
    ('8bc4fd9b-fe9e-4c94-880a-16584cc382ed'),
    ('32a4ad90-6fdd-4d80-a480-87c4360d2c5d'),
    ('f7f333cb-b42f-4787-812c-c2e8c6a2ccab'),
    ('70f92c0d-ce08-405e-85c0-717c790a877d'),
    ('7716ee0c-4751-4f12-9423-8a8907bad820'),
    ('e700a28f-708f-423b-8bec-f2cb6796743d'),
    ('5f04b237-e30b-4625-b002-26ca5aafe226'),
    ('317d993d-2b92-412d-b17e-f9292647c338'),
    ('1748c0e3-4b85-4de9-b9ab-781863698629'),
    ('93544ded-4cc8-4e17-a72b-971a7612a2b8'),
    ('1b052203-8f39-491a-b00e-d5d71ce8a32d'),
    ('e2e1bd9f-4ed2-4a4a-8da2-2b185935ae8b'),
    ('6d64e37b-e066-4362-82eb-5ae4dd42b3e3'),
    ('89d99481-951a-4e9f-ad7c-55ef695c198a'),
    ('45668382-01c6-4b8a-889d-7939fc983a60'),
    ('2a58de49-64e1-4658-9fac-0932fb404010'),
    ('9e143d0a-b8b0-44d4-b19f-0e55495ba91e'),
    ('2d45ec61-efc6-406b-8978-a1cc29c7e63a'),
    ('897750b9-8015-4829-ae4a-5bd7afbf932a'),
    ('bca119df-6d44-429f-aa7a-27f364145469'),
    ('71fcb034-dc45-48e2-ae80-a070c37ee99f'),
    ('4fa6eaa7-fec0-4a51-b34e-ba9b27369b5c'),
    ('c53d8660-8f26-48fd-af6e-698c023fc1ad'),
    ('0761330d-ff69-4661-beef-e26b4b333f28'),
    ('535178f0-01cf-4041-8a08-a9d28dab3ce3'),
    ('b85c2501-d404-499a-b893-8d9655b15384'),
    ('9ed24ec2-3766-4445-99e0-69e740c585a1'),
    ('d55f9809-3d50-4712-ab53-06e12f1d1155'),
    ('83bf11e1-8782-4d19-b6bc-7bc351222933'),
    ('54281ad7-e7b4-434f-9026-e7582396b846'),
    ('ffbc79d3-4e13-4ebc-ad16-f44379c1ef40'),
    ('5c9d18f7-913c-409e-b707-c69286d2d31a'),
    ('8e41a9bd-f216-48c5-ac4e-a955e10dde45'),
    ('ca7f52b4-4535-4482-b635-a690039654f8'),
    ('13439fdb-f94a-44d0-97bf-1ddb2237f0cd'),
    ('9f167e5e-f0c4-4fa5-b486-a00b721ae5c5'),
    ('4c875d03-95bd-4f57-b0eb-265d62e0801b'),
    ('7abe81f0-5b87-4b22-922f-9478f23e49bd'),
    ('cc59b253-4761-4e21-a557-e9c006aee2ff'),
    ('ecc41b67-8ee5-4764-a6c6-44f7cde5d926'),
    ('69f1b291-c1c4-43d4-a61e-453d6a38f635'),
    ('77bee623-38ea-4c60-bed0-3718a7714e1a'),
    ('c6d86310-60b3-4541-9d1d-09bfe31ba691'),
    ('e1f37be5-7321-4ced-af3c-7147e71a2094'),
    ('b95b5d02-dc26-4e6f-a7ac-45d3fd2fb261'),
    ('6ae82923-0b36-4bc2-9a3b-08e82c2bac1a'),
    ('26a084b6-03b0-4497-8e6c-3771e5adbad8'),
    ('395ea5e0-66f7-406c-b2e1-1f6e08b17361'),
    ('3d537c02-0817-422f-9e1a-99873213ee36'),
    ('6340b92a-7997-4e23-81b4-e52562f53638'),
    ('76f1c8d1-3425-4137-94d1-ce5def2ea325'),
    ('4f29db4e-dffd-4fe9-bcb6-7f04a5f1a474'),
    ('339ef40b-1062-41cf-934a-679faaa23be4'),
    ('1c1fa525-cbf9-419d-910a-b5b60cc20b26'),
    ('e11acb28-de91-4a53-90a4-cc1e00333b70'),
    ('94826f24-aac3-46c1-aca2-caa2ead6cd2e'),
    ('fc10f820-8aab-4afc-8983-9fd5289591a3'),
    ('6f00441d-7b6e-403f-92c5-b3134f13664c'),
    ('8bda14f1-12b1-41d2-8af5-596e9fa3bc78'),
    ('58b54493-fe9c-47b1-bffa-738665af2bab'),
    ('dfaeaebc-fe5f-4aae-9e84-1ab6073216f2'),
    ('6d3505ec-f342-40a0-a981-64937c3c4613'),
    ('c7e0bd11-0a1a-4b47-bde3-fbb88e431fba'),
    ('9ec4759b-52a4-46da-b098-8ede4b0ba227'),
    ('273630e5-c608-4c1d-a967-f36f086af9e5'),
    ('b6a8a421-786b-4792-a1e2-784d57d7178a'),
    ('b547e4ea-b356-4405-aab8-ad2180809824'),
    ('1d47d9b4-53bc-48d3-96fc-baef774cd626'),
    ('49681e94-e0e5-46a6-9408-3fdbf3ff0cd9'),
    ('36d6eca5-6a7a-4cd4-a211-387d32337d5a'),
    ('15754c0b-db4b-4a46-aa5c-a5a573f0fd08'),
    ('01329bfd-6f07-4a37-b1cf-48185f06c03c'),
    ('e9b90141-cbdd-4784-9976-3d7cad7f633d'),
    ('6b34580b-e7c0-42a3-b079-2c52a87a3a29'),
    ('55b2f2f5-14e8-4fda-a3c2-f22ef4f5fec6'),
    ('47b81fa9-0039-43f4-8ac6-e5c45d51832d'),
    ('ed957d8c-27e0-421f-84c0-f69094d68813'),
    ('6e1d3aab-a138-4677-b27c-8601597adbe4'),
    ('6d7a3f35-6ad9-439e-8a46-e41a5d85c13b'),
    ('6bfd8531-f058-4f1b-8275-f984c36cae40'),
    ('b980bb30-5a00-4267-ace8-3ed1fa9c34ea'),
    ('91675f7d-f4bd-42c3-a689-35669b337b79'),
    ('45781fe1-7d12-4eef-adb1-daa665fb7fbc'),
    ('fcf183a6-91e2-40a7-bddc-b4c757369163'),
    ('92d53d27-f7d8-484e-8dfb-6b1f3008110e'),
    ('165a8f92-3687-48b5-839a-8ba5f728e292'),
    ('ca1e5b96-1937-4b19-8a97-81fbff2b997c'),
    ('5081fd41-5be5-4405-b476-7f280e75ae81'),
    ('a9019e63-748e-4012-9622-eda533241757'),
    ('da0a2cc7-b6a0-4ac6-bf9d-3d53f142cc89'),
    ('7c0ace7f-d1b4-4c79-a421-8f7c2317f421'),
    ('950d7ec0-46ce-4b22-88da-5395afbc1379'),
    ('737d1f42-197e-4f27-83f5-75da7c1478ef'),
    ('df18754f-dbc4-426c-b054-2bf2f54e1149'),
    ('42694e3d-e675-4297-bf14-e7af273057b7'),
    ('e303ea38-5eb9-4ade-9ab8-a82cdd081c18'),
    ('8fe8e675-28aa-4758-ab15-b6f15e3e47d6'),
    ('8acb6d8c-f6ad-4e84-aaa6-d0565ea146c8'),
    ('9aa9b2f9-3d23-459a-8826-5f68c33aa078'),
    ('ad6627eb-4160-4b6c-8e47-e8956d72c3e7'),
    ('ccf9b6a0-7cc9-4e91-97ae-c66543d330c6'),
    ('ca38a03c-6135-439f-a4d4-75e53f1c94f0'),
    ('e4047e0a-818f-492b-93e4-701bbd6c2894'),
    ('db472770-5efa-4f64-82b5-318bc76f6b0e'),
    ('f0a7996b-bec6-4236-8be9-ecd8f5db5809'),
    ('a1d9879d-7d1d-4cb0-8fcf-019d6d5b999e'),
    ('287b4bcd-ddf4-4ec4-951a-2b4f6564eec5'),
    ('6d20b033-ed4b-49d6-be59-549fa74f801a'),
    ('2e178064-d83e-4b54-8cde-5e7d357bf78c'),
    ('ce4a4700-4d02-4c67-8641-e13fcf117359'),
    ('022e2d45-6b89-4276-a2fd-a82c3ae095b2'),
    ('5d421ab4-6629-4fcc-bb0a-24f0001d18d1'),
    ('ae90993c-dac1-40ac-aa2d-e08e6a30c670'),
    ('418ed32e-8bf5-4a8a-943e-7f1b4dc13c44'),
    ('d509b5b7-431d-4b60-93c6-42a959b5d3f7'),
    ('aed8fe2b-7fb1-4cd4-8f81-ef1241ee68d9'),
    ('8628fe7a-57f0-427d-b81f-6a0846af5617'),
    ('c76dbdd1-a719-47de-9b3b-d8147ddf94cc'),
    ('76729255-9f3e-4de8-9e43-80a217177fa4'),
    ('1228dbc8-8d6a-41ef-aa4f-e888d49b6f1a'),
    ('3939921f-ec65-41aa-a46d-2f3ef29a57da'),
    ('b101c5d6-fb1b-436d-a8c3-9ac678d5c7da'),
    ('c15f9dc0-6054-4800-b66b-92016c47112a'),
    ('5b8c78a2-fbc4-4954-afa1-2e7d8d9bdf73'),
    ('bad78eda-ecac-4c7d-a86d-cbf515604a0c'),
    ('057fad05-ef97-42d1-8cc5-da019775e2c9'),
    ('e4275f86-420f-4fd6-924c-75ff266689fc'),
    ('94bf024c-b082-41c6-a126-7189b2556d26'),
    ('92a9f8dc-e737-465a-96a3-18a9133628c3'),
    ('ec0ab006-24ba-48fc-a7e0-f96d32fc3af2'),
    ('4bed62ca-f931-4808-9519-cf8da5e31615'),
    ('93336f09-d280-43cb-b317-02e6c53d2523'),
    ('7048e089-da6c-4a9e-8cc1-433265a5b4bb'),
    ('bed07caa-0bd6-4e63-ad9a-e53fbff158e5'),
    ('1eb23103-1e55-48c9-ab8a-530528a0199c'),
    ('57f96acf-895b-42ea-b3b2-3e39bd888acd'),
    ('5926c04c-1fc3-42ef-94fd-034d008bae70'),
    ('6a359a61-2a2d-49c4-878c-39ca0153cca4'),
    ('45de8c7e-42ca-4772-ac5b-005a854c04fb'),
    ('792b87b4-9cab-4c14-b8c5-150eab17eddd'),
    ('8d95e128-30d6-4cdc-a4c7-d743f2c6c8ba'),
    ('298e17c1-8389-43fa-8f7f-cf357d786772'),
    ('b70b4b30-be91-4934-b596-5f7fbd0c7c94'),
    ('1b154756-08be-43ec-8da1-bd0112d61685'),
    ('2a556e0c-4ac8-4b39-8128-d59c2feef3a8'),
    ('654c9474-f2e1-4d99-a1e3-dc348ae571c8'),
    ('1c7ec75e-326d-418f-a000-c1afa47f080f'),
    ('e1d09053-0878-4aa3-8ea9-878755707126'),
    ('5d119f09-b69b-4942-b944-083128ee3814'),
    ('3649fb26-1972-4d8f-ac15-1723b3549443'),
    ('192b1b72-1427-4aed-964a-e154ed807854'),
    ('621ed988-f420-4f60-9b8c-586d90ff3cb9'),
    ('4e713699-f73c-4fba-8499-aec15663329c'),
    ('d844fd8f-3cea-4581-af88-09a37631f08d'),
    ('8a0d9a70-084e-4ea9-b2e1-4fbc4cf0729a'),
    ('57f84e2b-dbba-4d5d-a8ce-17b77bc5ac8b'),
    ('f68787fc-0a40-497d-ad5b-f8dbafba8af0'),
    ('c50421c0-0fc0-4994-80b5-e8a2d28eee7d'),
    ('d2058d04-3bef-4f2c-a47b-9e0adf33d187'),
    ('76d56e0b-0a6f-4082-89cd-0ae16102c2c5'),
    ('b92a6732-5bff-4665-a695-1dc85e995e42'),
    ('c1561ffd-7736-49ff-aecf-c6d21fa2ed8c'),
    ('aff96030-b972-41a8-8370-3c2b31b9ce01'),
    ('d45a4627-dce6-4d50-836e-d4906e591163'),
    ('b5916018-3a20-4ef8-859b-ec1cd2042829'),
    ('9423d533-12e1-48a0-a8b2-cd08bbe1c5de'),
    ('2a915444-fa68-4bd3-bab5-647a4759dd6a'),
    ('1ad75af2-dbd9-4303-8b5d-47077388a4dd'),
    ('d57110ec-bdf5-4755-a6db-19eb002a994a'),
    ('99d1aaaa-53a2-4733-966b-2bfb6ff83612'),
    ('85fde2b6-8952-4d99-900a-28a15b81c690'),
    ('dc5cac4e-46cf-4a45-81ed-428c1f334e12'),
    ('1918f4e2-8c89-418b-b889-e00e9a190c61'),
    ('45d89ea2-4977-4c0e-b188-d1319180aa11'),
    ('b111a0f3-e74f-4a93-a8ea-004be85fbf9e'),
    ('244858bc-9c32-4090-bf83-03799ee378bd'),
    ('5b2522e8-a26c-42fa-b34c-000ed0c403ba'),
    ('6bf1839d-8370-41ea-a72b-4b6c316c84e4'),
    ('43b5f234-cccd-42cc-9130-62a6d5e46b5c'),
    ('f90bc121-9aaa-4786-ac4e-565036ded46d'),
    ('78202b26-dd4a-4985-a780-4c113a3a5ab4'),
    ('94e8cc08-a4b0-403e-ba63-5052334a5b14'),
    ('2867cda6-8a85-4ef9-8592-1249abab5319'),
    ('44f6e414-99ca-462b-b2ab-0212fa7b28bd'),
    ('f5445844-438a-42d1-a42b-a6ea5a3a652d'),
    ('30fb9e5d-affc-43f2-9ef3-b06df0dc45de'),
    ('65ed2e4e-1d41-4692-a162-1c95de517d25'),
    ('fde8b18e-4174-4f72-a014-0cfc10db84bf'),
    ('3780dc93-36e4-45b7-b296-10ed0dbb7cec'),
    ('ae32e402-de2b-421e-8572-e959b4eb7aaf'),
    ('54689bae-c930-4ad1-ad50-14582a90e887'),
    ('ee4031d2-7f3c-41a7-99e7-d8c57323b83a'),
    ('c09603f8-6a0b-4506-87e6-9fb35d312bac'),
    ('76312670-f31c-47a9-af06-90af35c65f4c'),
    ('2adee660-51f2-4884-96d4-2f79acc05da4'),
    ('9d5f1ac4-39f9-4c82-be01-583a52c46ced'),
    ('8b5c8f08-b84e-4cba-8c65-a35628acf751'),
    ('8e4a9d87-8a1c-4940-84b4-3bdb6780ce9f'),
    ('d4ef261d-5f93-472d-b9ed-9ac6081a7144'),
    ('87528b3e-1061-46f5-bafa-16b92f4aae52'),
    ('60385e8c-f98b-4c0a-bfbc-98930637d7d5'),
    ('3e69f1de-ae29-482d-8819-c29b5c820436'),
    ('45051be3-b7a4-44f8-b22d-2c08272a7f31'),
    ('cb92a364-404f-4fa8-8412-9838279b6c11'),
    ('2c4217cc-c70a-43ab-bddd-efbd7b72d7de'),
    ('7555bcf7-04cb-4235-994a-08c6c087be82'),
    ('b3ded816-f8d0-46ca-8263-2b7c1ef4fa80'),
    ('53b44882-2d0f-4105-8877-74d06ae6818a'),
    ('4f864d65-439d-49ee-8732-abb19101ece9'),
    ('d3c7d0bf-e1d6-49c1-91f7-cf67a4c74caa'),
    ('277e56e4-4e4b-46e5-bbce-8166e24a50cd'),
    ('0d9a5b29-09ef-4f73-acf7-163286a5dc9d'),
    ('f6425a5c-4b9d-452a-a3c1-b7c1537fc381'),
    ('be0a31f7-7068-44a2-9ab6-097c020dfb65'),
    ('27af3160-fe0d-4e80-8fc5-fcccf37a4579'),
    ('14234935-3fe1-41b2-bf43-f678ff7f265f'),
    ('2189f149-66a9-48b1-b35f-4b938406687b'),
    ('d633ddd9-c546-4b9c-b6d4-b9de3d16dad6'),
    ('b2398e7b-60cc-4d0f-a1ad-92c3aa7542d2'),
    ('5233c147-11e9-4005-aad4-499dd3cddbe6'),
    ('1f7f38f8-7c34-45c7-9b23-dcbdf08a600f'),
    ('c5c1afe7-22f9-47b1-88f3-f4d9a81509f9'),
    ('5c32fd53-2469-4cce-9498-7248d18458bb'),
    ('a7858a65-008e-4f9d-ba1d-eac064383a46'),
    ('7a4a45c3-824a-4e70-8df9-e0ec52ef8d6e'),
    ('96fd6b84-6c86-455c-a2da-134261a0a1de'),
    ('06bd0300-ce40-45a9-9a2b-e136cfbbbcf4'),
    ('57b0b9fb-6959-4632-bc0f-25b2d7892d83')
    ;

CREATE TEMPORARY TABLE delete_organisms (
    organism_uuid uuid,
    PRIMARY KEY (organism_uuid)
) ;
INSERT INTO delete_organisms (organism_uuid) VALUES
    ('e76f3b98-72d3-4f86-8cb6-048990bca6de'),
    ('5b112f7a-092e-4937-b453-730b79604f9e'),
    ('e8df22f7-a048-4d81-9bd9-6751951d87b0'),
    ('c3fbd691-b707-4a99-8e01-970cf1e01b64'),
    ('ace70782-df77-468e-bfab-7639b868bf6f'),
    ('6893f699-5a6f-483f-95d2-4cdcc16f5882'),
    ('9c848722-dc95-41d8-95a6-661a5e1d841f'),
    ('db9826d5-bcbd-4699-9d29-a37dfd29d054'),
    ('eb3b2700-a29e-4d5a-9223-30a2842727b5'),
    ('69ab4eac-0105-4dfc-bf6a-843e300eba87'),
    ('277e08b3-6c08-4547-a6dd-1763c56f18a0'),
    ('e607b541-0688-4054-b371-1c6d4b5039ac'),
    ('dab1f890-d3fc-4d6d-90d1-95a33e8a4516'),
    ('2994cf85-528a-4ba9-b179-a8c342d5daeb'),
    ('de8efad9-8fb0-4a81-a0ab-5948198fd73a'),
    ('77990712-e2f1-4537-aee4-5fdd0d9e4be5'),
    ('2d049a77-d78e-41e2-a6b2-2e4b4f3d2307'),
    ('5a433bd0-2020-25d9-e053-2614a8c026f8'),
    ('5a433bd0-2000-25d9-e053-2614a8c026f8'),
    ('39717455-b30b-4138-8418-53f7c71f4e61'),
    ('62f6dc18-1b60-0553-e053-2614a8c052d6'),
    ('c813a9e2-ff9d-451b-a16b-7f24f395faa4'),
    ('5a433bd0-2007-25d9-e053-2614a8c026f8'),
    ('5a433bd0-1fbb-25d9-e053-2614a8c026f8'),
    ('5f301924-f1f4-5da1-e053-2614a8c0f028'),
    ('62f6dc18-1b62-0553-e053-2614a8c052d6'),
    ('8e60145e-a94e-414e-aa2f-ba8cf0a533e0'),
    ('d0782d2f-ebbe-4570-b93e-d301cad017a9'),
    ('266b049e-7968-402c-be94-c580f95be5fd'),
    ('62f6dc18-1b61-0553-e053-2614a8c052d6'),
    ('5a433bd0-20df-25d9-e053-2614a8c026f8'),
    ('5a433bd0-2001-25d9-e053-2614a8c026f8'),
    ('4c4547fd-f6da-41f2-a095-b944b7e2a2d2'),
    ('5fa9bca0-f24a-40f9-e053-2614a8c0a9a2'),
    ('5a433bd0-20e1-25d9-e053-2614a8c026f8'),
    ('dfd17675-30dd-4440-b259-41e0adbaa14d'),
    ('5a433bd0-2121-25d9-e053-2614a8c026f8'),
    ('5a433bd0-20e3-25d9-e053-2614a8c026f8'),
    ('64bd1f0f-e4a0-420b-bc1f-2a4659701f7f'),
    ('5a433bd0-2075-25d9-e053-2614a8c026f8'),
    ('5a433bd0-1ff6-25d9-e053-2614a8c026f8'),
    ('5a433bd0-1fdb-25d9-e053-2614a8c026f8'),
    ('5a433bd0-1ffc-25d9-e053-2614a8c026f8'),
    ('6ca0e0fe-4ec7-498a-9c6f-5364039b79bc'),
    ('5a433bd0-207b-25d9-e053-2614a8c026f8'),
    ('3a664509-d805-438f-8f33-ad22c19ced31'),
    ('5a433bd0-1feb-25d9-e053-2614a8c026f8'),
    ('5a433bd0-20e0-25d9-e053-2614a8c026f8'),
    ('5a433bd0-20de-25d9-e053-2614a8c026f8'),
    ('844d5334-2017-4caf-974f-728cf24e3bd1'),
    ('5a433bd0-1f9f-25d9-e053-2614a8c026f8'),
    ('5a433bd0-1ff0-25d9-e053-2614a8c026f8'),
    ('5f301924-f1f5-5da1-e053-2614a8c0f028'),
    ('ff8a606c-52c5-4385-9596-f57ce3378d54'),
    ('c40bcd88-e2a9-410a-bd49-c2e4ec3b9fa0'),
    ('a87c1173-469e-43f4-8ecc-7e7bdea76d8e'),
    ('a5e89832-daf7-46c4-be62-09b32b071a92'),
    ('05cb2483-7b09-4f99-aac9-80cdba9bc860'),
    ('742a67d5-de06-471e-8262-668b8e1b2c70'),
    ('e6603719-9e6b-448f-b35d-176ae922b15e'),
    ('97cff968-6e21-4fdc-8c45-1eecc270b2b6'),
    ('d58a1fcd-4700-4ce9-bae0-9d4a8068bada'),
    ('5e40dcb3-6d66-4e25-8647-8d9e00a6c396'),
    ('c788efdc-5a59-4192-95b9-1683c10d4001'),
    ('a6bf71e1-f505-4353-a3bb-3635ebf687c3'),
    ('da45d092-0607-47a7-bccd-ad403b0c8b78'),
    ('8c0d894b-290e-4f95-8134-0d9d11fd6b5d'),
    ('19c9490f-70f7-4935-be98-1db045858b7a'),
    ('05e17b63-ea80-4adf-9154-34ae01607b67'),
    ('9c20a7ef-13f5-48e8-a03c-fb8fc7248de9'),
    ('ca348a12-7808-42e4-91b2-e8f2b9d0bd25'),
    ('6b18761e-0a24-49b1-96cd-6c16a284059f'),
    ('84ce30b5-0371-4a58-9515-0470d625e053'),
    ('f5aceb32-f4de-4e62-8abb-0cbd197c70b3'),
    ('da208268-192e-4d73-be5d-2d3959b80497'),
    ('0d7dc468-a74a-4280-95e6-10e5299c16ef'),
    ('7de9d003-0550-4a19-8696-767c7dda1a95'),
    ('b1fbf6ba-3ad6-43e6-903a-580ef7a00f54'),
    ('113710f7-1661-482d-9d51-d992ad390a7c'),
    ('0c6553db-5365-4e51-a3bc-586ef9a225f7'),
    ('f0e12c40-f965-4f36-beff-8438b5e42637'),
    ('d52df58e-f9bb-4e93-9ea4-c976eeb5323d'),
    ('00b38f16-a86e-44df-8595-84701b17f070'),
    ('321813f9-5a3c-44ac-9bea-903d824e5e2a'),
    ('5bfef5ac-51b5-4a5e-b072-d85092f4fa9c'),
    ('05c60810-6ed9-460a-b205-05ff6b5893d8'),
    ('d87981fe-dc2c-43dd-a781-44290d65980b'),
    ('843d775a-e856-4470-9fc6-c62bf2c8ea35'),
    ('78de10cd-5bbc-4bbb-ac7a-1a2025d5f17a'),
    ('fd754ad2-7824-4905-9859-fbfc11fc1a86'),
    ('000bfa26-d3c6-4c98-9d2f-92eb5ec59756'),
    ('5730955a-588a-4b80-9919-56a62db141bc'),
    ('cf1e42f9-e6a1-467e-96ec-d25ad3a2bb89'),
    ('cadb37d5-5eea-48b4-8971-4cb87e9a7165'),
    ('0fdcd723-5303-4ba1-952f-7e514d5b6e75'),
    ('32d394ec-d807-4542-9129-a2ebdbc46fd8')
    ;

CREATE TEMPORARY TABLE delete_acquisition_frameworks (
    unique_acquisition_framework uuid,
    PRIMARY KEY (unique_acquisition_framework)
) ;
INSERT INTO delete_acquisition_frameworks (unique_acquisition_framework) VALUES
    ('e7935970-de15-4db4-a723-466f68844a67'),
    ('4a9dda1f-b62b-3e13-e053-2614a8c02b7c'),
    ('5f4d2d3d-5d05-4cb4-9fae-d3388e8a8148'),
    ('4a9dda1f-b641-3e13-e053-2614a8c02b7c'),
    ('bd862615-4f13-4494-98ec-95ddf78fa59c'),
    ('e6ff1f31-ae49-43f8-8a09-d60f38b33543'),
    ('d7c988da-98ed-48c2-9fe9-e018d5c6d021'),
    ('4a9dda1f-b616-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b651-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b6ce-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b615-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b6c7-3e13-e053-2614a8c02b7c'),
    ('a6397ef2-4560-46d1-aff1-d3ebe29abf78'),
    ('193def61-8ede-4922-b89c-6e81288affee'),
    ('4a9dda1f-b601-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b646-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b5e7-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b647-3e13-e053-2614a8c02b7c'),
    ('369b5996-1ddd-491d-a0ed-782681c4c430'),
    ('4a9dda1f-b5ff-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b688-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b66f-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b6b3-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b681-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b63e-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b630-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b6b0-3e13-e053-2614a8c02b7c'),
    ('000bed33-5d6a-47a4-a203-d9af201b304c'),
    ('dd832bfe-5f0c-401d-aa39-c955bd4e2a7e'),
    ('4a9dda1f-b693-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b61d-3e13-e053-2614a8c02b7c'),
    ('6b38df84-3004-38df-e053-2614a8c09b0f'),
    ('4a9dda1f-b5f8-3e13-e053-2614a8c02b7c'),
    ('01a24f6b-a175-4d9a-b25b-cb1bfbc9692d'),
    ('4a9dda1f-b619-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b632-3e13-e053-2614a8c02b7c'),
    ('fee36233-2ece-4c08-8df4-2a16b8e252f0'),
    ('4a9dda1f-b626-3e13-e053-2614a8c02b7c'),
    ('951d7090-4b5d-42a6-9dcf-45a2bd3ba407'),
    ('4a9dda1f-b613-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b692-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b5fa-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b645-3e13-e053-2614a8c02b7c'),
    ('4a9dda1f-b66d-3e13-e053-2614a8c02b7c'),
    ('91f147de-20f9-42e0-8668-dc1e4c3d3a5b') ;

DELETE FROM gn_synthese.cor_area_synthese AS a
USING gn_synthese.synthese AS s,
    gn_meta.t_datasets AS td,
    gn_meta.t_acquisition_frameworks AS af,
    delete_acquisition_frameworks AS df
WHERE a.id_synthese = s.id_synthese
    AND s.id_dataset = td.id_dataset
    AND td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_synthese.synthese AS s
USING  gn_meta.t_datasets AS td,
    gn_meta.t_acquisition_frameworks AS af,
    delete_acquisition_frameworks AS df
WHERE s.id_dataset = td.id_dataset
    AND td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_synthese.t_sources AS sou
USING gn_synthese.synthese AS s
WHERE sou.id_source = s.id_source
    AND s.id_synthese IS NULL;

DELETE FROM gn_meta.cor_dataset_actor AS ac
USING  gn_meta.t_datasets AS td,
    gn_meta.t_acquisition_frameworks AS af,
    delete_acquisition_frameworks AS df
WHERE ac.id_dataset = td.id_dataset
    AND td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_dataset_territory AS te
USING  gn_meta.t_datasets AS td,
    gn_meta.t_acquisition_frameworks AS af,
    delete_acquisition_frameworks AS df
WHERE te.id_dataset = td.id_dataset
    AND td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_dataset_protocol AS pro
USING  gn_meta.t_datasets AS td,
    gn_meta.t_acquisition_frameworks AS af,
    delete_acquisition_frameworks AS df
WHERE pro.id_dataset = td.id_dataset
    AND td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.t_datasets AS td
USING gn_meta.t_acquisition_frameworks af, delete_acquisition_frameworks AS df
WHERE  td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_actor AS ac
USING  gn_meta.t_acquisition_frameworks AS af, delete_acquisition_frameworks AS df
WHERE ac.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_objectif AS obj
USING  gn_meta.t_acquisition_frameworks AS af, delete_acquisition_frameworks AS df
WHERE obj.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_publication AS pub
USING  gn_meta.t_acquisition_frameworks AS af, delete_acquisition_frameworks AS df
WHERE pub.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_voletsinp AS si
USING  gn_meta.t_acquisition_frameworks AS af, delete_acquisition_frameworks AS df
WHERE si.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.t_acquisition_frameworks AS af
USING delete_acquisition_frameworks AS df
WHERE af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM utilisateurs.cor_roles AS cr
USING utilisateurs.t_roles AS r
WHERE cr.id_role_utilisateur = r.id_role
    AND uuid_role IN (SELECT role_uuid FROM delete_roles);

DELETE FROM utilisateurs.t_roles
WHERE uuid_role IN (SELECT role_uuid FROM delete_roles);

DELETE FROM utilisateurs.bib_organismes
WHERE uuid_organisme IN (SELECT organism_uuid FROM delete_organisms);

DO $$
    BEGIN
        IF EXISTS
            ( SELECT 1
                FROM   information_schema.tables
                WHERE  table_schema = 'gn2pg_flavia'
                AND    table_name = 'data_json'
            )
        THEN
            UPDATE gn2pg_flavia.data_json
            SET id_data = id_data ;
        END IF ;
    END
$$ ;

COMMIT;

-- Script to move Postgres tables and indexes of Gn2Pg LPO schema to new TableStorage

-- Move gn2pg_lpo tables
ALTER TABLE gn2pg_lpo.data_json SET TABLESPACE tmp_data_storage;
ALTER TABLE gn2pg_lpo.import_log SET TABLESPACE tmp_data_storage;
ALTER TABLE gn2pg_lpo.metadata_json SET TABLESPACE tmp_data_storage;
ALTER TABLE gn2pg_lpo.error_log SET TABLESPACE tmp_data_storage;



-- Move gn2pg_lpo indexes
ALTER INDEX gn2pg_lpo.pk_source_data SET TABLESPACE tmp_data_storage;
ALTER INDEX gn2pg_lpo.ix_gn2pg_lpo_data_json_id_data SET TABLESPACE tmp_data_storage;
ALTER INDEX gn2pg_lpo.ix_gn2pg_lpo_data_json_uuid SET TABLESPACE tmp_data_storage;
ALTER INDEX gn2pg_lpo.unique_uuid SET TABLESPACE tmp_data_storage;
ALTER INDEX gn2pg_lpo.import_log_pkey SET TABLESPACE tmp_data_storage;
ALTER INDEX gn2pg_lpo.ix_gn2pg_lpo_import_log_source SET TABLESPACE tmp_data_storage;
ALTER INDEX gn2pg_lpo.ix_gn2pg_lpo_import_log_xfer_type SET TABLESPACE tmp_data_storage;
ALTER INDEX gn2pg_lpo.pk_source_metadata SET TABLESPACE tmp_data_storage;
ALTER INDEX gn2pg_lpo.metadata_unique_uuid SET TABLESPACE tmp_data_storage;

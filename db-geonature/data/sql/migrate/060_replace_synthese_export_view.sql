
-- Replace synthese export views
-- Required rights: DB OWNER
-- Transfert this script on server this way:
-- rsync -av ./001_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db -f ~/data/db-geonature/data/sql/001_*

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Recreate VIEW gn_synthese.v_synthese_taxon_for_export_view'
DROP VIEW IF EXISTS gn_synthese.v_synthese_taxon_for_export_view ;

CREATE OR REPLACE VIEW gn_synthese.v_synthese_taxon_for_export_view AS
WITH s AS ( SELECT DISTINCT cd_nom FROM gn_synthese.synthese )
    SELECT
        ref.nom_valide,
        ref.cd_ref,
        ref.nom_vern,
        ref.group1_inpn,
        ref.group2_inpn,
        ref.regne,
        ref.phylum,
        ref.classe,
        ref.ordre,
        ref.famille,
        ref.id_rang
    FROM s
        JOIN taxonomie.taxref AS t ON s.cd_nom = t.cd_nom
        JOIN taxonomie.taxref AS ref ON t.cd_ref = ref.cd_nom;

\echo '----------------------------------------------------------------------------'
COMMIT;

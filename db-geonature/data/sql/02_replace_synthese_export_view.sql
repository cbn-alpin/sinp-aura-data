
-- Droits d'éxecution nécessaire : DB OWBER
-- Replace synthese export views
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Recreate VIEW gn_synthese.v_synthese_for_export'
-- Ajout des colonnes id_nomenclature_sensitivity et id_nomenclature_diffusion_level (obligatoires)
-- Suppression de toutes les colonnes inutiles
DROP VIEW gn_synthese.v_synthese_for_export ;

CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export
AS SELECT s.id_synthese,
    s.unique_id_sinp AS uuid_perm_sinp,
    s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
    af.acquisition_framework_name AS ca_nom,
    d.id_dataset AS jdd_id,
    d.unique_dataset_id AS jdd_uuid,
    d.dataset_name AS jdd_nom,
    n21.label_default AS niveau_validation,
    s.validator AS validateur,
    s.observers AS observateurs,
    t.cd_ref,
    t.nom_valide,
    s.count_min AS nombre_min,
    s.count_max AS nombre_max,
    s.date_min::DATE AS date_debut,
    s.date_max::DATE AS date_fin,
    st_asgeojson(s.the_geom_4326) AS geojson_4326,
    st_asgeojson(s.the_geom_local) AS geojson_local,
    s."precision" AS precision_geographique,
    n9.label_default AS niveau_precision_diffusion,
    s.id_digitiser,
    s.id_nomenclature_sensitivity,
    s.id_nomenclature_diffusion_level
FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_meta.t_acquisition_frameworks af ON d.id_acquisition_framework = af.id_acquisition_framework
     LEFT JOIN ref_nomenclatures.t_nomenclatures n9 ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n21 ON s.id_nomenclature_valid_status = n21.id_nomenclature ;

\echo '----------------------------------------------------------------------------'
\echo 'Recreate VIEW gn_synthese.v_synthese_taxon_for_export_view'
DROP VIEW gn_synthese.v_synthese_taxon_for_export_view ;

CREATE OR REPLACE VIEW gn_synthese.v_synthese_taxon_for_export_view
AS WITH s AS (SELECT DISTINCT cd_nom FROM gn_synthese.synthese )
	SELECT
		REF.nom_valide,
		REF.cd_ref,
		REF.nom_vern,
		REF.group1_inpn,
		REF.group2_inpn,
		REF.regne,
		REF.phylum,
		REF.classe,
		REF.ordre,
		REF.famille,
		REF.id_rang
	FROM s
		JOIN taxonomie.taxref t ON s.cd_nom = t.cd_nom
		JOIN taxonomie.taxref REF ON t.cd_ref = REF.cd_nom;

\echo '----------------------------------------------------------------------------'
COMMIT;

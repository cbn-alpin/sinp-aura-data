-- Create materialized views unique indexes to enable concurrent refresh usage

-- Enable timing
\timing

BEGIN;

\echo '----------------------------------------------------------------'
\echo 'Add unique indexes'

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_synthese_blurred
ON gn_exports.synthese_blurred (id_synthese, id_area) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_catalog_taxa_region
ON gn_exports.catalog_taxa_region (cd_ref) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_pnr_haut_jura_blurred
ON gn_exports.pnr_haut_jura_blurred (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_pnr_livradois_forez_blurred
ON gn_exports.pnr_livradois_forez_blurred (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_pnr_massif_bauges_blurred
ON gn_exports.pnr_massif_bauges_blurred (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_pnr_pilat_blurred
ON gn_exports.pnr_pilat_blurred (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_pnr_vercors_blurred_1
ON gn_exports.pnr_vercors_blurred_1 (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_pnr_vercors_blurred_2
ON gn_exports.pnr_vercors_blurred_2 (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_pnr_volcans_auvergne_blurred_1
ON gn_exports.pnr_volcans_auvergne_blurred_1 (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_pnr_volcans_auvergne_blurred_2
ON gn_exports.pnr_volcans_auvergne_blurred_2 (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_pnr_volcans_auvergne_blurred_3
ON gn_exports.pnr_volcans_auvergne_blurred_3 (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_lo_parvi_1
ON gn_exports.lo_parvi_1 (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_lo_parvi_2
ON gn_exports.lo_parvi_2 (id_synthese) ;

CREATE UNIQUE INDEX IF NOT EXISTS unique_idx_pnr_chartreuse
ON gn_exports.pnr_chartreuse (id_synthese) ;


\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;

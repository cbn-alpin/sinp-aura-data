-- Ajout d'index sur la table cor_area_sythese pour éviter les requête lentes dans Biodiv'territoire
-- au niveau des listes d'espèce par mailles de la carte affichée.

CREATE INDEX cor_area_synthese_id_synthese_idx ON gn_synthese.cor_area_synthese (id_synthese);

CREATE INDEX cor_area_synthese_id_area_idx ON gn_synthese.cor_area_synthese (id_area);

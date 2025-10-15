-- Add values to Campanule nomenclature
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
--
-- Transfert this script on server with Git or this way:
--      rsync -av ./011_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way:
--      psql -h localhost -U geonatadmin -d geonature2db -f ./011_*

BEGIN ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert new values to Campanule nomenclature:'

INSERT INTO ref_nomenclatures.t_nomenclatures (
    id_type,
    cd_nomenclature,
    mnemonique,
    label_default,
    definition_default,
    label_fr,
    definition_fr,
    "source",
    statut,
    id_broader,
    "hierarchy",
    active
)
VALUES
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2001',
    'Entomocénotique',
    'Entomocénotique',
    'Application des principes de la phytosociologie aux communautés d''insectes (Orthoptères) : dans un secteur géographique et climatique donné, lorsque les conditions stationnelles sont les mêmes, on observe presque toujours les mêmes espèces ensemble. Des relevés orthoptériques sont effectués par identification à vue ou à l''ouïe des espèces (voire par capture directe) au cours de déplacements libres dans la station.',
    'Entomocénotique',
    'Application des principes de la phytosociologie aux communautés d''insectes (Orthoptères) : dans un secteur géographique et climatique donné, lorsque les conditions stationnelles sont les mêmes, on observe presque toujours les mêmes espèces ensemble. Des relevés orthoptériques sont effectués par identification à vue ou à l''ouïe des espèces (voire par capture directe) au cours de déplacements libres dans la station.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2001',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2002',
    'Capture-Marquage-Recapture / Capture-Recapture',
    'Capture-Marquage-Recapture / Capture-Recapture',
    'Méthode d''échantillonnage qui consiste à capturer, à marquer puis à recapturer des individus sur le même site afin d''y estimer l''abondance d''une population et sa structure démographique. En répétant les occasions de capture, le taux de reprise d’individus déjà marqués permet d''estimer une probabilité de capture, et ainsi de corriger les effectifs observés en estimant le nombre d’individus non détectés. L''abondance est estimée en fonction du taux de recapture d''individus marqués. Pour estimer la densité locale, ces valeurs d’abondance sont rapportées à la surface effectivement utilisée par les animaux détectés. Cette méthode permet aussi d''étudier les déplacements des individus et dans certains cas les dimensions de leur habitat et leur organisation spatiale. Sur le même principe, mais sans marquage, la photo-identification utilise les motifs uniques (exemple : répartition des taches sur le pelage du Lynx boréal) et autres caractères physiques propres à chaque individu (exemple : découpage de la nageoire caudale chez la Baleine à bosse) permettant une reconnaissance et un suivi individuel sur la base de photographies (correspondant à des événements de "capture-recapture").',
    'Capture-Marquage-Recapture / Capture-Recapture',
    'Méthode d''échantillonnage qui consiste à capturer, à marquer puis à recapturer des individus sur le même site afin d''y estimer l''abondance d''une population et sa structure démographique. En répétant les occasions de capture, le taux de reprise d’individus déjà marqués permet d''estimer une probabilité de capture, et ainsi de corriger les effectifs observés en estimant le nombre d’individus non détectés. L''abondance est estimée en fonction du taux de recapture d''individus marqués. Pour estimer la densité locale, ces valeurs d’abondance sont rapportées à la surface effectivement utilisée par les animaux détectés. Cette méthode permet aussi d''étudier les déplacements des individus et dans certains cas les dimensions de leur habitat et leur organisation spatiale. Sur le même principe, mais sans marquage, la photo-identification utilise les motifs uniques (exemple : répartition des taches sur le pelage du Lynx boréal) et autres caractères physiques propres à chaque individu (exemple : découpage de la nageoire caudale chez la Baleine à bosse) permettant une reconnaissance et un suivi individuel sur la base de photographies (correspondant à des événements de "capture-recapture").',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2002',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2003',
    'Distance sampling par line-transect',
    'Distance sampling par line-transect',
    'Méthode d''échantillonnage par la distance de détection. Estimation d''abondance et de densité à partir de mesures de distances entre l’observateur et les individus observés de part et d’autre d’un transect linéaire (en ligne d''une longueur donnée) ou ponctuel (l''observateur se déplace le long d''un transect mais le relevé s''effectue sur un point fixe sur ce transect, détaillé au n°2004 de ce catalogue). Les transects sont choisis aléatoirement ou en série de lignes parallèles systématiquement espacées avec un point de départ aléatoire. La distance de chaque individu détecté par rapport à la ligne est notée, et c''est la distribution de ces distances qui permet d''estimer la proportion d''individus détectés, et donc la densité et l''abondance de la population. Cette méthode permet d''évaluer dans quelle mesure notre capacité à détecter les individus diffère dans différents habitats et à différents moments.',
    'Distance sampling par line-transect',
    'Méthode d''échantillonnage par la distance de détection. Estimation d''abondance et de densité à partir de mesures de distances entre l’observateur et les individus observés de part et d’autre d’un transect linéaire (en ligne d''une longueur donnée) ou ponctuel (l''observateur se déplace le long d''un transect mais le relevé s''effectue sur un point fixe sur ce transect, détaillé au n°2004 de ce catalogue). Les transects sont choisis aléatoirement ou en série de lignes parallèles systématiquement espacées avec un point de départ aléatoire. La distance de chaque individu détecté par rapport à la ligne est notée, et c''est la distribution de ces distances qui permet d''estimer la proportion d''individus détectés, et donc la densité et l''abondance de la population. Cette méthode permet d''évaluer dans quelle mesure notre capacité à détecter les individus diffère dans différents habitats et à différents moments.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2003',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2004',
    'Distance sampling par point-transect',
    'Distance sampling par point-transect',
    'Méthode d''échantillonnage par la distance de détection. Estimation d''abondance et de densité à partir de mesures de distances entre l’observateur et les individus observés de part et d’autre d’un transect linéaire (en ligne d''une longueur donnée, détaillé au n°3 de ce catalogue) ou ponctuel (l''observateur se déplace le long d''un transect mais le relevé s''effectue sur un point fixe sur ce transect). Les points sont prédéfinis. La distance de chaque individu détecté par rapport au point est notée, et c''est la distribution de ces distances qui permet d''estimer la proportion d''individus détectés, et donc la densité et l''abondance de la population. Elle permet d''évaluer dans quelle mesure notre capacité à détecter les individus diffère dans différents habitats et à différents moments. Cette méthode est surtout utilisée pour les points d''écoute d''oiseaux pendant la reproduction, mais aussi pour certains mammifères discrets lorsqu''on utilise des points-pièges et / ou des points appâtés : ces derniers attirent les individus vers un point, et permettent potentiellement une estimation de l''abondance des espèces qui peuvent être piégées, avec moins de ressources nécessaires que les campagnes de piégeage classiques et les méthodes conventionnelles de marquage-recapture.',
    'Distance sampling par point-transect',
    'Méthode d''échantillonnage par la distance de détection. Estimation d''abondance et de densité à partir de mesures de distances entre l’observateur et les individus observés de part et d’autre d’un transect linéaire (en ligne d''une longueur donnée, détaillé au n°3 de ce catalogue) ou ponctuel (l''observateur se déplace le long d''un transect mais le relevé s''effectue sur un point fixe sur ce transect). Les points sont prédéfinis. La distance de chaque individu détecté par rapport au point est notée, et c''est la distribution de ces distances qui permet d''estimer la proportion d''individus détectés, et donc la densité et l''abondance de la population. Elle permet d''évaluer dans quelle mesure notre capacité à détecter les individus diffère dans différents habitats et à différents moments. Cette méthode est surtout utilisée pour les points d''écoute d''oiseaux pendant la reproduction, mais aussi pour certains mammifères discrets lorsqu''on utilise des points-pièges et / ou des points appâtés : ces derniers attirent les individus vers un point, et permettent potentiellement une estimation de l''abondance des espèces qui peuvent être piégées, avec moins de ressources nécessaires que les campagnes de piégeage classiques et les méthodes conventionnelles de marquage-recapture.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2004',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2005',
    'Indice Horaire d''Abondance (IHA)',
    'Indice Horaire d''Abondance (IHA)',
    'Méthode d''évaluation de l''abondance d''une population par comptage pendant une heure de déplacement libre sur une station. Les comptages obtenus sont ramenés à l’unité de temps (i.e. 1 heure), pour aboutir à un indice horaire d’abondance propre à chaque espèce (et à un indice cénotique global, toutes espèces confondues, qui est la somme des indices précédents). Cet indice permet ensuite de déterminer le nombre d’individus pour 100 m2.',
    'Indice Horaire d''Abondance (IHA)',
    'Méthode d''évaluation de l''abondance d''une population par comptage pendant une heure de déplacement libre sur une station. Les comptages obtenus sont ramenés à l’unité de temps (i.e. 1 heure), pour aboutir à un indice horaire d’abondance propre à chaque espèce (et à un indice cénotique global, toutes espèces confondues, qui est la somme des indices précédents). Cet indice permet ensuite de déterminer le nombre d’individus pour 100 m2.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2005',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2006',
    'Indice Kilométrique d''Abondance (IKA)',
    'Indice Kilométrique d''Abondance (IKA)',
    'Méthode de mesure de l''abondance relative d''espèces le long d''un circuit. Trajet parcouru par l''observateur à vitesse constante, espèces rencontrées (vues, entendues ou indices de présence) notées tout comme leur position sur le transect (avec répétition). L''indice exprime le rapport du nombre total d''individus (ou d''indices de présence) observés le long d''un transect sur la longueur totale du transect parcouru sur chaque site.',
    'Indice Kilométrique d''Abondance (IKA)',
    'Méthode de mesure de l''abondance relative d''espèces le long d''un circuit. Trajet parcouru par l''observateur à vitesse constante, espèces rencontrées (vues, entendues ou indices de présence) notées tout comme leur position sur le transect (avec répétition). L''indice exprime le rapport du nombre total d''individus (ou d''indices de présence) observés le long d''un transect sur la longueur totale du transect parcouru sur chaque site.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2006',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2007',
    'Indice Linéaire d''Abondance (ILA)',
    'Indice Linéaire d''Abondance (ILA)',
    'Méthode relative d''estimation de l''abondance d''une population. L''observateur effectue différents transects linéaires de 10 m sans recoupement sur lesquels il compte le nombre d''individus observés (sur une bande d’environ un mètre de largeur).',
    'Indice Linéaire d''Abondance (ILA)',
    'Méthode relative d''estimation de l''abondance d''une population. L''observateur effectue différents transects linéaires de 10 m sans recoupement sur lesquels il compte le nombre d''individus observés (sur une bande d’environ un mètre de largeur).',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2007',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2008',
    'Point d''écoute ou Indice Ponctuel d''Abondance (IPA)',
    'Point d''écoute ou Indice Ponctuel d''Abondance (IPA)',
    'Méthode d''estimation de l''abondance relative d''une population et de ses variations au cours du temps. Repose sur un point d''écoute (ou d''observation) fixe de durée limitée (20 mn dans la version de Blondel 1970) sur lequel l''observateur recense l''ensemble des espèces contactées (observées et / ou entendues) sans limitation de distance, avec répétition de la session de comptage. Cette méthode a été étendue à des durées différentes de la version de Blondel (1970) et l’indice correspond au nombre moyen d''individus observés ou entendus par secteur pendant cette durée. Dans son principe cette méthode est analogue à celle des IKA (référencée au n°2006 de ce catalogue) à la différence près qu''au lieu de parcourir un itinéraire donné sur une distance de longueur connue, l''observateur reste immobile pendant une durée déterminée.',
    'Point d''écoute ou Indice Ponctuel d''Abondance (IPA)',
    'Méthode d''estimation de l''abondance relative d''une population et de ses variations au cours du temps. Repose sur un point d''écoute (ou d''observation) fixe de durée limitée (20 mn dans la version de Blondel 1970) sur lequel l''observateur recense l''ensemble des espèces contactées (observées et / ou entendues) sans limitation de distance, avec répétition de la session de comptage. Cette méthode a été étendue à des durées différentes de la version de Blondel (1970) et l’indice correspond au nombre moyen d''individus observés ou entendus par secteur pendant cette durée. Dans son principe cette méthode est analogue à celle des IKA (référencée au n°2006 de ce catalogue) à la différence près qu''au lieu de parcourir un itinéraire donné sur une distance de longueur connue, l''observateur reste immobile pendant une durée déterminée.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2008',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2009',
    'Capture-suivi (radiotracking, radiopistage, radiotélémesure)',
    'Capture-suivi (radiotracking, radiopistage, radiotélémesure)',
    'Méthode de localisation et suivi des déplacements des individus marqués par un émetteur radio (émetteurs d''ondes métriques (VHF), terminal de l''émetteur de la plateforme (PTT) et émetteurs satelittaires du Système de positionnement global (GPS, Argos)) et toute autre technologie ayant la même finalité (communications cellulaires, géolocalisation solaire, radar, etc.).',
    'Capture-suivi (radiotracking, radiopistage, radiotélémesure)',
    'Méthode de localisation et suivi des déplacements des individus marqués par un émetteur radio (émetteurs d''ondes métriques (VHF), terminal de l''émetteur de la plateforme (PTT) et émetteurs satelittaires du Système de positionnement global (GPS, Argos)) et toute autre technologie ayant la même finalité (communications cellulaires, géolocalisation solaire, radar, etc.).',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2009',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2010',
    'Présence-absence, occupation de site (site occupancy)',
    'Présence-absence, occupation de site (site occupancy)',
    'Méthode d''estimation de la probabilité de présence d''une espèce sur un site par la répétition d''observations (présence-absence) en tenant compte de sa détectabilité. Evalue la proportion de sites occupés, dont la valeur est corrigée par la probabilité de détection de l''espèce.',
    'Présence-absence, occupation de site (site occupancy)',
    'Méthode d''estimation de la probabilité de présence d''une espèce sur un site par la répétition d''observations (présence-absence) en tenant compte de sa détectabilité. Evalue la proportion de sites occupés, dont la valeur est corrigée par la probabilité de détection de l''espèce.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2010',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2011',
    'Echantillonnages Fréquentiels Progressifs (EFP)',
    'Echantillonnages Fréquentiels Progressifs (EFP)',
    'Méthode de relevé de la présence/absence des espèces basé sur le nombre de contacts (fréquences) visuels ou auditifs sur un site en un temps donné. Comme il s''agit de relevés en présence –absence, elle ne permet pas d''obtenir des densités, mais d''évaluer la richesse du peuplement. Contrairement à l''indice ponctuel d''abondance (IPA, répertorié au n°2008 de ce catalogue) et de l''Indice Kilométrique d''Abondance (IKA, répertorié au n°2006 de ce catalogue), l''Echantillonnage Fréquentiel Progressif (EFP) est une méthode qualitative, appliquée à un certain nombre de stations prédéfinies dans un milieu donné. Le terme « progressif » indique que la précision de l''information augmente avec l''intensité de l''échantillonnage (nombre de prospections aux points d''écoute).',
    'Echantillonnages Fréquentiels Progressifs (EFP)',
    'Méthode de relevé de la présence/absence des espèces basé sur le nombre de contacts (fréquences) visuels ou auditifs sur un site en un temps donné. Comme il s''agit de relevés en présence –absence, elle ne permet pas d''obtenir des densités, mais d''évaluer la richesse du peuplement. Contrairement à l''indice ponctuel d''abondance (IPA, répertorié au n°2008 de ce catalogue) et de l''Indice Kilométrique d''Abondance (IKA, répertorié au n°2006 de ce catalogue), l''Echantillonnage Fréquentiel Progressif (EFP) est une méthode qualitative, appliquée à un certain nombre de stations prédéfinies dans un milieu donné. Le terme « progressif » indique que la précision de l''information augmente avec l''intensité de l''échantillonnage (nombre de prospections aux points d''écoute).',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2011',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2012',
    'Plans quadrillés ou cartographie des territoires (densité absolue)',
    'Plans quadrillés ou cartographie des territoires (densité absolue)',
    'Méthode de relevé répété d''observations d''individus pendant la saison de reproduction sur une aire déterminée, de superficie réduite et adaptée à la taille du territoire connue de l''espèce recherchée, et qui soit représentative de l''habitat étudié et définie par un plan quadrillé standardisé. Appelée aussi "méthode de cartographie des territoires d''oiseaux". On choisit de petites parcelles (10 à 30 ha en général) lorsque l''on travaille sur de petites espèces d''oiseaux ou bien en milieu forestier, et des grandes parcelles (50 à 200 ha ou 40 à 100 ha selon les références bibliographiques) pour les espèces à vastes territoires ou dans un milieu ouvert. Cette aire est délimitée par des lignes de base balisées et mesurées ; on établit ensuite une grille de deux séries de lignes parallèles se recoupant à angles droits. Les points d''intersection sont jalonnés de manière à permettre un repérage facile de chacun des points à l''intérieur du périmètre. Les observations sont reportées sur ce plan quadrillé sur la carte, où sont évalués les territoires. Le nombre et la durée des visites ne sont ni définis, ni limités mais il est recommandé pour ce groupe de réaliser un nombre minimum de 8 visites en milieu ouvert et de 10 en milieu fermé. Cette méthode permet d''obtenir une connaissance quasi exhaustive du peuplement d''oiseaux ayant niché sur le quadrat.',
    'Plans quadrillés ou cartographie des territoires (densité absolue)',
    'Méthode de relevé répété d''observations d''individus pendant la saison de reproduction sur une aire déterminée, de superficie réduite et adaptée à la taille du territoire connue de l''espèce recherchée, et qui soit représentative de l''habitat étudié et définie par un plan quadrillé standardisé. Appelée aussi "méthode de cartographie des territoires d''oiseaux". On choisit de petites parcelles (10 à 30 ha en général) lorsque l''on travaille sur de petites espèces d''oiseaux ou bien en milieu forestier, et des grandes parcelles (50 à 200 ha ou 40 à 100 ha selon les références bibliographiques) pour les espèces à vastes territoires ou dans un milieu ouvert. Cette aire est délimitée par des lignes de base balisées et mesurées ; on établit ensuite une grille de deux séries de lignes parallèles se recoupant à angles droits. Les points d''intersection sont jalonnés de manière à permettre un repérage facile de chacun des points à l''intérieur du périmètre. Les observations sont reportées sur ce plan quadrillé sur la carte, où sont évalués les territoires. Le nombre et la durée des visites ne sont ni définis, ni limités mais il est recommandé pour ce groupe de réaliser un nombre minimum de 8 visites en milieu ouvert et de 10 en milieu fermé. Cette méthode permet d''obtenir une connaissance quasi exhaustive du peuplement d''oiseaux ayant niché sur le quadrat.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2012',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2013',
    'Méthode de Daget-Poissonet (points contacts, ligne contact)',
    'Méthode de Daget-Poissonet (points contacts, ligne contact)',
    'Méthode d''estimation de la richesse floristique linéaire utilisée pour apprécier la structure horizontale de la végétation en milieu herbacé. Appelée aussi "méthode des points quadrats alignés" ou du "double-mètre", elle consiste à effectuer des mesures sur une ligne horizontale graduée, le long de laquelle l''opérateur fait glisser une aiguille positionnée à la verticale. Le recouvrement de chaque espèce est mesuré sur chaque point disposé régulièrement le long de la ligne qui entre en contact avec une feuille ou une tige : on parle alors de points contacts (et on mesure un contact par espèce). Plusieurs variantes existent, notamment la méthode des "points quadrats" qui consiste à positionner les contacts non pas le long d''une ligne mais sur un réseau de fils tendus à l''intérieur d''un quadrat, et varient en fonction du matériel utilisé. La plus courante est la méthode de DAGET et POISSONET. L''échantillonnage est systématique : on determine toutes les espèces végétales présentes. La fréquence de chaque plante au niveau de chaque point permettra d''évaluer l''abondance relative des espèces, les unes par rapport aux autres.',
    'Méthode de Daget-Poissonet (points contacts, ligne contact)',
    'Méthode d''estimation de la richesse floristique linéaire utilisée pour apprécier la structure horizontale de la végétation en milieu herbacé. Appelée aussi "méthode des points quadrats alignés" ou du "double-mètre", elle consiste à effectuer des mesures sur une ligne horizontale graduée, le long de laquelle l''opérateur fait glisser une aiguille positionnée à la verticale. Le recouvrement de chaque espèce est mesuré sur chaque point disposé régulièrement le long de la ligne qui entre en contact avec une feuille ou une tige : on parle alors de points contacts (et on mesure un contact par espèce). Plusieurs variantes existent, notamment la méthode des "points quadrats" qui consiste à positionner les contacts non pas le long d''une ligne mais sur un réseau de fils tendus à l''intérieur d''un quadrat, et varient en fonction du matériel utilisé. La plus courante est la méthode de DAGET et POISSONET. L''échantillonnage est systématique : on determine toutes les espèces végétales présentes. La fréquence de chaque plante au niveau de chaque point permettra d''évaluer l''abondance relative des espèces, les unes par rapport aux autres.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2013',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2014',
    'Relevé phytosociologique (De Foucault-Gillet-Julve, phytosociologie synusiale intégrée)',
    'Relevé phytosociologique (De Foucault-Gillet-Julve, phytosociologie synusiale intégrée)',
    'Principe de la phytosociologie, c''est-à-dire l''étude des communautés végétales reposant sur des inventaires floristiques à partir desquels peuvent être mis en évidence des ensembles d''espèces (notions de groupements végétaux, de formations végétales ou de végétations) en relation avec les conditions du milieu (sol, climat, etc). La phytosociologie synusiale intégrée s''intéresse aux synusies végétales, c''est-à-dire des communautés très homogènes du point de vue fonctionnel écologique qui regroupent des espèces qui vivent ensemble et ont des stratégies de vie similaires. Les relations entre elles sont étudiées après cette analyse fine. Cette méthode repose sur un inventaire exhaustif des espèces sur plusieurs strates. Il s''agit de lister les plantes présentes sur une surface échantillon au moins égale à l''aire minimale, représentative d''une communauté végétale floristiquement homogène correspondant à certaines conditions écologiques bien définies. Un des points cruciaux de l''approche synusiale consiste en la prise en compte des types biologiques.',
    'Relevé phytosociologique (De Foucault-Gillet-Julve, phytosociologie synusiale intégrée)',
    'Principe de la phytosociologie, c''est-à-dire l''étude des communautés végétales reposant sur des inventaires floristiques à partir desquels peuvent être mis en évidence des ensembles d''espèces (notions de groupements végétaux, de formations végétales ou de végétations) en relation avec les conditions du milieu (sol, climat, etc). La phytosociologie synusiale intégrée s''intéresse aux synusies végétales, c''est-à-dire des communautés très homogènes du point de vue fonctionnel écologique qui regroupent des espèces qui vivent ensemble et ont des stratégies de vie similaires. Les relations entre elles sont étudiées après cette analyse fine. Cette méthode repose sur un inventaire exhaustif des espèces sur plusieurs strates. Il s''agit de lister les plantes présentes sur une surface échantillon au moins égale à l''aire minimale, représentative d''une communauté végétale floristiquement homogène correspondant à certaines conditions écologiques bien définies. Un des points cruciaux de l''approche synusiale consiste en la prise en compte des types biologiques.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2014',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL'),
    '2015',
    'Relevé phytosociologique (Braun-Blanquet, phytosociologie sigmatiste)',
    'Relevé phytosociologique (Braun-Blanquet, phytosociologie sigmatiste)',
    'Principe de la phytosociologie, c''est-à-dire l''étude des communautés végétales reposant sur des inventaires floristiques à partir desquels peuvent être mis en évidence des ensembles d''espèces (notions de groupements végétaux, de formations végétales ou de végétations) en relation avec les conditions du milieu (sol, climat, etc). La phytosociologie sigmatiste (relative à l''école SIGMA (station internationale de géobotanique méditerranéenne et alpine fondée à Montpellier par J. Braun-Blanquet) repose sur les associations végétales, c''est-à-dire les groupements végétaux stables et en équilibre avec le milieu ambiant caractérisé par une composition floristique déterminée dans laquelle certains éléments révèlent par leur présence une écologie particulière et autonome ; ces éléments floristiques sont des espèces caractéristiques. Il s''agit d''une démarche en deux temps qui comprend une étape analytique (une phase de terrain qui consiste à réaliser les relevés en ayant au préalable défini les aires à échantillonner), suivie d''une étape synthétique (une phase post-terrain qui consiste à structurer et analyser les données afin d''en déterminer le nom des associations végétales). Il s''agit d''une méthode de description de la végétation. Les relevés floristiques en présence-absence sont réalisés dans des quadrats ou le long de transects, à l''horizontale et à la verticale, sans notion de strate, et servent de base au calcul de différents indices (abondance-dominance, agrégation, valeur pastorale, etc.). La phytosociologie sigmatiste ne prend pas en compte la dynamique de la communauté, mais la fidélité des espèces au sein des syntaxons de base que sont les associations végétales.',
    'Relevé phytosociologique (Braun-Blanquet, phytosociologie sigmatiste)',
    'Principe de la phytosociologie, c''est-à-dire l''étude des communautés végétales reposant sur des inventaires floristiques à partir desquels peuvent être mis en évidence des ensembles d''espèces (notions de groupements végétaux, de formations végétales ou de végétations) en relation avec les conditions du milieu (sol, climat, etc). La phytosociologie sigmatiste (relative à l''école SIGMA (station internationale de géobotanique méditerranéenne et alpine fondée à Montpellier par J. Braun-Blanquet) repose sur les associations végétales, c''est-à-dire les groupements végétaux stables et en équilibre avec le milieu ambiant caractérisé par une composition floristique déterminée dans laquelle certains éléments révèlent par leur présence une écologie particulière et autonome ; ces éléments floristiques sont des espèces caractéristiques. Il s''agit d''une démarche en deux temps qui comprend une étape analytique (une phase de terrain qui consiste à réaliser les relevés en ayant au préalable défini les aires à échantillonner), suivie d''une étape synthétique (une phase post-terrain qui consiste à structurer et analyser les données afin d''en déterminer le nom des associations végétales). Il s''agit d''une méthode de description de la végétation. Les relevés floristiques en présence-absence sont réalisés dans des quadrats ou le long de transects, à l''horizontale et à la verticale, sans notion de strate, et servent de base au calcul de différents indices (abondance-dominance, agrégation, valeur pastorale, etc.). La phytosociologie sigmatiste ne prend pas en compte la dynamique de la communauté, mais la fidélité des espèces au sein des syntaxons de base que sont les associations végétales.',
    'SINP',
    'Validé',
    0,
    ref_nomenclatures.get_id_nomenclature_type('METHO_RECUEIL')||'.'||'2015',
    TRUE
);


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;

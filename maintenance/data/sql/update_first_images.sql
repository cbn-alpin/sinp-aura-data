-- SQL query to update first image in taxonomie.t_medias table when first image have already been selected.
WITH exists_first_medias AS (
    SELECT
        cd_ref
    FROM
        taxonomie.t_medias AS stm
    WHERE
        id_type = 1
),
priority_first_medias AS (
    SELECT
        1 AS priority,
        MIN(id_media) AS first_id_media_founded,
        cd_ref
    FROM
        taxonomie.t_medias
    WHERE
        cd_ref NOT IN (
            SELECT
                cd_ref
            FROM
                exists_first_medias
        )
        AND "source" != 'INPN'
        AND supprime != TRUE
    GROUP BY
        cd_ref
    UNION
    SELECT
        2 AS priority,
        MIN(id_media) AS first_id_media_founded,
        cd_ref
    FROM
        taxonomie.t_medias
    WHERE
        cd_ref NOT IN (
            SELECT
                cd_ref
            FROM
                exists_first_medias
        )
        AND "source" = 'INPN'
        AND supprime != TRUE
    GROUP BY
        cd_ref
),
first_medias AS (
    SELECT
        DISTINCT ON (pfm.cd_ref) pfm.cd_ref,
        pfm.priority,
        pfm.first_id_media_founded
    FROM
        priority_first_medias AS pfm
    ORDER BY
        pfm.cd_ref,
        pfm.priority
)
UPDATE
    taxonomie.t_medias AS tm
SET
    id_type = 1
FROM
    first_medias AS fm
WHERE
    tm.id_media = fm.first_id_media_founded
    AND tm.cd_ref = fm.cd_ref;

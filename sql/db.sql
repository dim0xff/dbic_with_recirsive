BEGIN;

DROP TABLE IF EXISTS "categories" CASCADE;
DROP SEQUENCE IF EXISTS "categories_id_seq";


CREATE SEQUENCE "categories_id_seq" START 1;

CREATE TABLE "categories"  (
    "id"                bigint DEFAULT NEXTVAL('categories_id_seq')  NOT NULL PRIMARY KEY,
    "parent_id"         bigint              NULL,
    "title"             varchar(256)        NOT NULL,
    "position"          int                 NOT NULL DEFAULT 0,

    CONSTRAINT "parent_category" FOREIGN KEY("parent_id") REFERENCES "categories"("id")
);

CREATE INDEX ON "categories"("parent_id");



--
-- Categories ancestors tree
--

CREATE OR REPLACE FUNCTION get_category_ancestors(bigint) RETURNS SETOF categories AS $$
DECLARE
    _category_id ALIAS FOR $1;
BEGIN
    RETURN QUERY
        WITH RECURSIVE
        q AS (
            SELECT c.*,  0 AS ordering
                FROM categories c
                WHERE id = _category_id

            UNION ALL

            SELECT  ca.*,  ordering + 1
                FROM q
                JOIN categories ca
                    ON ca.id = q.parent_id
        )
        SELECT "id", "parent_id", "title", "position"
            FROM q
            WHERE ordering > 0
            ORDER BY ordering DESC;
END;
$$ LANGUAGE plpgsql;


--
-- Categories descendants tree
--

CREATE OR REPLACE FUNCTION get_category_descendants(bigint, int) RETURNS SETOF categories AS $$
DECLARE
    _category_id ALIAS FOR $1;  -- category id
    _max_level   ALIAS FOR $2;  -- max level for looking in
BEGIN
    RETURN QUERY
        WITH RECURSIVE
        q AS (
            SELECT  c.*, ARRAY[position::bigint, id] AS ordering, 0 as "level"
                FROM categories c
                WHERE  ( _category_id IS     NULL AND parent_id IS NULL )
                    OR ( _category_id IS NOT NULL AND id = _category_id )


            UNION ALL

            SELECT  cd.*, q.ordering || cd.position::bigint || cd.id, q."level" + 1
                FROM q
                    JOIN categories cd
                        ON cd.parent_id = q.id
                WHERE
                         _max_level IS NULL
                    OR ( _max_level IS NOT NULL AND "level" + 1 < _max_level )
        )
        SELECT "id", "parent_id", "title", "position"
            FROM q
            WHERE ( _category_id IS NULL OR "level" > 0 )
            ORDER BY ordering;
END;
$$ LANGUAGE plpgsql;

COMMIT;

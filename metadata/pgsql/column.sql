            SELECT  C.*, 
                    d.description AS COLUMN_COMMENT
            FROM	INFORMATION_SCHEMA.COLUMNS C
            INNER   JOIN pg_catalog.pg_class o ON o.relname = C.TABLE_NAME AND to_regnamespace(C.TABLE_SCHEMA)::oid = o.relnamespace
            LEFT    JOIN pg_catalog.pg_description d ON d.objoid = o.oid AND d.objsubid = C.ordinal_position
            WHERE   table_schema not in ('pg_catalog','information_schema')

            SELECT
                    T.*, 
                    d.description AS TABLE_COMMENT,
                    s.n_live_tup AS TABLE_ROWS
            FROM	INFORMATION_SCHEMA.TABLES T
            INNER   JOIN pg_catalog.pg_class o ON o.relname = T.TABLE_NAME AND to_regnamespace(T.TABLE_SCHEMA)::oid = o.relnamespace
            LEFT    JOIN pg_catalog.pg_description d ON d.objoid = o.oid AND d.objsubid = 0
            LEFT    JOIN pg_stat_user_tables s ON s.schemaname = T.TABLE_SCHEMA AND s.relname = T.TABLE_NAME
            WHERE   table_schema not in ('pg_catalog','information_schema')

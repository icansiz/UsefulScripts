            SELECT	T.*,
                    o.create_date AS CREATE_TIME,
                    o.modify_date AS UPDATE_TIME,
                    (SELECT SUM (rows) FROM sys.partitions WHERE object_id=o.object_id  AND (index_id<2)) 
                    AS TABLE_ROWS,
                    (SELECT top 1 CAST(value as VARCHAR(4000)) from sys.extended_properties e WHERE e.major_id = o.object_id and minor_id=0 and name='MS_Description')
                    AS TABLE_COMMENT
            FROM	INFORMATION_SCHEMA.TABLES T
            INNER JOIN sys.objects o ON o.name = T.TABLE_NAME and SCHEMA_NAME(o.schema_id) = T.TABLE_SCHEMA

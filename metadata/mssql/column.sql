SELECT	C.*,
		(SELECT top 1 CAST(value as VARCHAR(4000)) FROM
			fn_listextendedproperty (NULL, 'schema', C.TABLE_SCHEMA, 'table', C.TABLE_NAME , 'column', C.COLUMN_NAME) 
		)
		AS COLUMN_COMMENT
FROM	INFORMATION_SCHEMA.COLUMNS C
INNER JOIN sys.objects o ON o.name = C.TABLE_NAME and SCHEMA_NAME(o.schema_id) = C.TABLE_SCHEMA

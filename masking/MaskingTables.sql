CREATE TABLE dbo.msk_tables (TableId INT, TableName VARCHAR(250), TableKey VARCHAR(100))
CREATE TABLE dbo.msk_columns (TableId INT, ColumnName VARCHAR(250)) 

CREATE TABLE dbo.msk_values (ColumnName VARCHAR(50), ColumnValue VARCHAR(100), Guid UNIQUEIDENTIFIER, SequenceId INT, NewSequenceId INT)
CREATE INDEX IDX_NameValue ON dbo.msk_values (ColumnName, ColumnValue)
CREATE INDEX IDX_NameSequence ON dbo.msk_values (ColumnName, SequenceId)

CREATE TABLE dbo.msk_table_ids (RowId INT IDENTITY  primary key, Id BIGINT, IsMasked BIT) 

CREATE TABLE dbo.tmp_columns (ColumnName VARCHAR(250)) 

-- Table 1
INSERT INTO dbo.msk_tables SELECT 1,'dbo.Person', 'PersonId'
INSERT INTO dbo.msk_columns (TableId, ColumnName) VALUES (1,'FirstName'),(1,'MiddleName'),(1,'LastName'), (1,'SocialSecurityNumber'), (1,'BirthDate'),(1,'PhoneNumber')

-- Table 2
INSERT INTO dbo.msk_tables SELECT 2,'dbo.Organization', 'OrganizationId'
INSERT INTO dbo.msk_columns (TableId, ColumnName) VALUES (1,'OrganizationName'),(2,'TaxId'),(2,'ContactPersonName')

DECLARE @TableName VARCHAR(250) 
DECLARE @TableKey VARCHAR(100) 
DECLARE @Collate VARCHAR(100) = ''
DECLARE @TableId INT 
DECLARE @Columns TABLE (ColumnName VARCHAR(100))
DECLARE @BatchSize INT = 10000


SET NOCOUNT ON;
WHILE 1 = 1
BEGIN	
	SELECT TOP 1 @TableId = TableId, @TableName = TableName, @TableKey = TableKey FROM dbo.msk_tables
	IF @@ROWCOUNT != 1
		BREAK

	TRUNCATE TABLE dbo.msk_values
	TRUNCATE TABLE dbo.msk_table_ids
	RAISERROR(N'TABLE..: %s',0, 1,@TableName) WITH NOWAIT;

	DECLARE @SQL NVARCHAR(2000) = ''

	SET @SQL = 'INSERT INTO dbo.msk_table_ids SELECT ' + @TableKey + ',0 FROM ' + @TableName 
	RAISERROR(@SQL,0, 1) WITH NOWAIT;
	EXEC sp_executesql  @SQL
	
	DECLARE @MaxRowId INT = (select Max(RowId) FROM dbo.msk_table_ids)
	DECLARE @ColumnName VARCHAR(100)

	TRUNCATE TABLE dbo.tmp_columns
	INSERT INTO dbo.tmp_columns SELECT ColumnName FROM dbo.msk_columns WHERE TableId = @TableId
	WHILE 1=1 
	BEGIN
		SELECT TOP 1 @ColumnName = ColumnName FROM dbo.tmp_columns
		IF @@ROWCOUNT != 1
			BREAK

		SET @SQL = 'INSERT INTO dbo.msk_values (ColumnName, ColumnValue) SELECT DISTINCT ''' + @ColumnName + ''', '+  @ColumnName + ' FROM ' + @TableName + '(NOLOCK) WHERE ISNULL('+@ColumnName+','''') != '''''
		RAISERROR(@SQL,0, 1) WITH NOWAIT;
		EXEC sp_executesql  @SQL
		DELETE FROM dbo.tmp_columns WHERE ColumnName = @ColumnName
	END 

	UPDATE dbo.msk_values SET Guid = NEWID()
	;
	WITH UpdateSequences AS (
		SELECT ColumnName, ColumnValue, Guid, SequenceId, NewSequenceId, 
			RowNum = ROW_NUMBER() OVER(PARTITION BY ColumnName ORDER BY ColumnName, ColumnValue),
			NewRowNum = ROW_NUMBER() OVER(PARTITION BY ColumnName ORDER BY ColumnName, Guid)
		FROM dbo.msk_values 
	)
	UPDATE UpdateSequences SET SequenceId = RowNum, NewSequenceId = NewRowNum

	DECLARE @RowIdFrom INT = 0, @RowIdTo INT = 0
	DECLARE @Count INT = 0;
	WHILE @Count < @MaxRowId
	BEGIN
		SET @RowIdTo = IIF(@Count+@BatchSize > @MaxRowId, @MaxRowId, @Count+@BatchSize)
		SET @RowIdFrom = @Count+1
		TRUNCATE TABLE dbo.tmp_columns
		INSERT INTO dbo.tmp_columns SELECT ColumnName FROM dbo.msk_columns WHERE TableId = @TableId
		WHILE 1=1
		BEGIN
			SELECT TOP 1 @ColumnName = ColumnName FROM dbo.tmp_columns
			IF @@ROWCOUNT != 1
				BREAK

			SET @SQL = 'UPDATE t SET t.' + @ColumnName + ' = new.ColumnValue' + 
					' FROM dbo.msk_table_ids ti' + 
					' INNER JOIN ' + @TableName + ' t ON ti.Id = t.' + @TableKey + 
					--' FROM ' + @TableName + ' t' + 
					' INNER JOIN dbo.msk_values v ON v.ColumnName = ''' + @ColumnName + ''' AND v.ColumnValue = t.' + @ColumnName + CASE WHEN @Collate != '' THEN ' COLLATE ' + @Collate ELSE '' END +
					' INNER JOIN dbo.msk_values new ON new.ColumnName = ''' + @ColumnName +''' AND new.SequenceId = v.NewSequenceId' + 
					' WHERE	ti.RowId BETWEEN @RowIdFrom AND @RowIdTo'
			RAISERROR(N'%d - %d - %d : %s',0, 1,@RowIdFrom, @RowIdTo, @MaxRowId, @SQL)  WITH NOWAIT;
			EXEC sp_executesql  @SQL, N'@RowIdFrom INT, @RowIdTo INT', @RowIdFrom, @RowIdTo
			DELETE FROM dbo.tmp_columns WHERE ColumnName = @ColumnName
		END
		SET @Count += @BatchSize
	END
	DELETE FROM dbo.msk_tables WHERE TableId = @TableId
END 

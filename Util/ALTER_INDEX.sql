SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
CREATE TABLE #FragmentedIndexes
(
 DatabaseName SYSNAME
 , SchemaName SYSNAME
 , TableName SYSNAME
 , IndexName SYSNAME
 , [Fragmentation%] FLOAT
)

INSERT INTO #FragmentedIndexes
SELECT
 DB_NAME(DB_ID()) AS DatabaseName
 , ss.name AS SchemaName
 , OBJECT_NAME (s.object_id) AS TableName
 , i.name AS IndexName
 , s.avg_fragmentation_in_percent AS [Fragmentation%]
FROM sys.dm_db_index_physical_stats(db_id(),NULL, NULL, NULL, 'SAMPLED') s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id]
AND s.index_id = i.index_id
INNER JOIN sys.objects o ON s.object_id = o.object_id
INNER JOIN sys.schemas ss ON ss.[schema_id] = o.[schema_id]
WHERE s.database_id = DB_ID()
AND i.index_id != 0
AND s.record_count > 0
AND o.is_ms_shipped = 0

DECLARE @RebuildIndexesSQL NVARCHAR(MAX)
SET @RebuildIndexesSQL = ''
SELECT
 @RebuildIndexesSQL = @RebuildIndexesSQL +
CASE
 WHEN [Fragmentation%] > 30
   THEN CHAR(10) + 'ALTER INDEX ' + QUOTENAME(IndexName) + ' ON '
      + QUOTENAME(SchemaName) + '.'
      + QUOTENAME(TableName) + ' REBUILD;'
 WHEN [Fragmentation%] > 10
    THEN CHAR(10) + 'ALTER INDEX ' + QUOTENAME(IndexName) + ' ON '
    + QUOTENAME(SchemaName) + '.'
    + QUOTENAME(TableName) + ' REORGANIZE;'
END
FROM #FragmentedIndexes
WHERE [Fragmentation%] > 10

DECLARE @StartOffset INT
DECLARE @Length INT
SET @StartOffset = 0
SET @Length = 4000
WHILE (@StartOffset < LEN(@RebuildIndexesSQL))
BEGIN
 PRINT SUBSTRING(@RebuildIndexesSQL, @StartOffset, @Length)
 SET @StartOffset = @StartOffset + @Length
END
PRINT SUBSTRING(@RebuildIndexesSQL, @StartOffset, @Length)
EXECUTE sp_executesql @RebuildIndexesSQL
DROP TABLE #FragmentedIndexes


SELECT DB_NAME() AS DbName,
name AS FileName,
size/128.0 AS CurrentSizeMB,
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB,
((size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0) / (size/128.0)) * 100 AS PercentFreeSpace
FROM sys.database_files;


SELECT OBJECT_NAME(i.OBJECT_ID) AS TableName,
i.name AS IndexName,
indexstats.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') indexstats
INNER JOIN sys.indexes i ON i.OBJECT_ID = indexstats.OBJECT_ID
AND i.index_id = indexstats.index_id
WHERE indexstats.avg_fragmentation_in_percent > 20


DECLARE @cmd VARCHAR(1000);
DECLARE cIndex CURSOR FOR
SELECT 'ALTER INDEX ALL ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID)) + '.' + QUOTENAME(name) + ' REBUILD;'
  FROM sys.tables
 ORDER BY OBJECT_SCHEMA_NAME(OBJECT_ID), name;
OPEN cIndex
FETCH NEXT FROM cIndex INTO @cmd;
WHILE @@FETCH_STATUS = 0 BEGIN
  RAISERROR(@cmd, 10, 1) WITH NOWAIT;
  EXEC (@cmd);
  FETCH NEXT FROM cIndex INTO @cmd;
END;
CLOSE cIndex;
DEALLOCATE cIndex;

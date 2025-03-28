IF OBJECT_ID('absp_Util_IndexInfo') IS NOT NULL DROP PROC absp_Util_IndexInfo
GO

CREATE PROCEDURE absp_Util_IndexInfo
 @tblPat sysname = '%'
,@missing_ix tinyint = 1
AS
--Written by Tibor Karaszi 2008-07-07
--Last modified by Tibor Karaszi 2009-02-19
WITH key_columns AS
(
SELECT
 c.OBJECT_ID
,c.name AS column_name
,ic.key_ordinal
,ic.is_included_column
,ic.index_id
,ic.is_descending_key
FROM sys.columns AS c
 INNER JOIN sys.index_columns AS ic ON c.OBJECT_ID = ic.OBJECT_ID AND ic.column_id = c.column_id
)
, physical_info AS
(
SELECT p.OBJECT_ID, p.index_id, ds.name AS location, SUM(p.rows) AS rows, SUM(a.total_pages) AS pages
FROM sys.partitions AS p
 INNER JOIN sys.allocation_units AS a ON p.hobt_id = a.container_id
 INNER JOIN sys.data_spaces AS ds ON a.data_space_id = ds.data_space_id
GROUP BY OBJECT_ID, index_id, ds.name
)
SELECT
 OBJECT_SCHEMA_NAME(i.OBJECT_ID) AS schema_name
,OBJECT_NAME(i.OBJECT_ID) AS table_name
,i.name AS index_name
,CASE i.type
  WHEN 0 THEN 'heap'
  WHEN 1 THEN 'cl'
  WHEN 2 THEN 'nc'
  WHEN 3 THEN 'xml'
  ELSE CAST(i.type AS VARCHAR(2))
 END
 AS type
,i.is_unique
,CASE
  WHEN is_primary_key = 0 AND is_unique_constraint = 0 THEN 'no'
  WHEN is_primary_key = 1 AND is_unique_constraint = 0 THEN 'PK'
  WHEN is_primary_key = 0 AND is_unique_constraint = 1 THEN 'UQ'
 END
 AS cnstr
,STUFF((SELECT CAST(', ' + kc.column_name + CASE kc.is_descending_key
                                             WHEN 0 THEN ''
                                             ELSE ' DESC'
                                             END
               AS VARCHAR(MAX))
 AS [text()]
FROM key_columns AS kc
WHERE i.OBJECT_ID = kc.OBJECT_ID AND i.index_id = kc.index_id AND kc.is_included_column = 0
ORDER BY key_ordinal
FOR XML PATH('')
 ), 1, 2, '') AS key_columns
,STUFF((SELECT CAST(', ' + column_name AS VARCHAR(MAX)) AS [text()]
  FROM key_columns AS kc
  WHERE i.OBJECT_ID = kc.OBJECT_ID AND i.index_id = kc.index_id AND kc.is_included_column = 1
  ORDER BY key_ordinal
  FOR XML PATH('')
 ), 1, 2, '') AS included_columns
--,i.filter_definition -- 2008
,p.location
,p.rows
,p.pages
,CAST((p.pages * 8.00) / 1024 AS decimal(9,2)) AS MB
,s.user_seeks
,s.user_scans
,s.user_lookups
,s.user_updates
FROM sys.indexes AS i
 LEFT OUTER JOIN physical_info AS p
  ON i.OBJECT_ID = p.OBJECT_ID AND i.index_id = p.index_id
 LEFT OUTER JOIN sys.dm_db_index_usage_stats AS s
  ON s.OBJECT_ID = i.OBJECT_ID AND s.index_id = i.index_id AND s.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.OBJECT_ID, 'IsMsShipped') = 0
 AND OBJECTPROPERTY(i.OBJECT_ID, 'IsTableFunction') = 0
 AND OBJECT_NAME(i.OBJECT_ID) LIKE @tblPat
ORDER BY table_name, index_name

IF @missing_ix = 1
BEGIN
SELECT
 OBJECT_SCHEMA_NAME(d.OBJECT_ID) AS schema_name
,OBJECT_NAME(d.OBJECT_ID) AS table_name
,'CREATE INDEX <IndexName> ON ' + OBJECT_SCHEMA_NAME(d.OBJECT_ID) + '.' + OBJECT_NAME(d.OBJECT_ID) + ' '
 + '(' + COALESCE(d.equality_columns + COALESCE(', ' + d.inequality_columns, ''), d.inequality_columns) + ')'
 + COALESCE(' INCLUDE(' + d.included_columns + ')', '')
 AS ddl
,s.user_seeks
,s.user_scans
,s.avg_user_impact
FROM sys.dm_db_missing_index_details AS d
 INNER JOIN  sys.dm_db_missing_index_groups AS g
  ON d.index_handle = g.index_handle
 INNER JOIN sys.dm_db_missing_index_group_stats AS s
  ON g.index_group_handle = s.group_handle
WHERE OBJECT_NAME(d.OBJECT_ID) LIKE @tblPat
AND d.database_id = DB_ID()
ORDER BY avg_user_impact DESC
END

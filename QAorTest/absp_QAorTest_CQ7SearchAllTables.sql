if exists(select 1 from SYSOBJECTS where id = object_id(N'absp_QAorTest_CQ7SearchAllTables') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure absp_QAorTest_CQ7SearchAllTables
end
go

CREATE PROC absp_QAorTest_CQ7SearchAllTables
(
    @SearchStr nvarchar(100)
)
AS
BEGIN

    -- Copyright 2002 Narayana Vyas Kondreddi. All rights reserved.
    -- Purpose: To search all columns of all tables for a given search string
    -- Written by: Narayana Vyas Kondreddi
    -- Site: http://vyaskn.tripod.com
    -- Tested on: SQL Server 7.0 and SQL Server 2000
    -- Date modified: 28th July 2002 22:50 GMT


    CREATE TABLE #Results (ColumnName nvarchar(370) COLLATE SQL_Latin1_General_CP1_CI_AS, Defect varchar(13) COLLATE SQL_Latin1_General_CP1_CI_AS, ColumnValue nvarchar(3630) COLLATE SQL_Latin1_General_CP1_CI_AS)

    SET NOCOUNT ON

    DECLARE @TableName nvarchar(256)
    DECLARE @TableName2 nvarchar(256)
    DECLARE @ColumnName nvarchar(128)
    DECLARE @SearchStr2 nvarchar(110)

    SET @TableName = ''
    SET @TableName2 = ''
    SET @SearchStr2 = QUOTENAME('%' + @SearchStr + '%','''')

    WHILE @TableName IS NOT NULL
    BEGIN
        SET @ColumnName = ''
        SET @TableName =
        (
            SELECT MIN(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))
            FROM   INFORMATION_SCHEMA.TABLES
            WHERE  TABLE_TYPE = 'BASE TABLE'
                AND QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) > @TableName
                AND OBJECTPROPERTY(
                        OBJECT_ID(
                            QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
                        ), 'IsMSShipped'
                    ) = 0
        )
        SET @TableName2 =
        (
            SELECT MIN(TABLE_NAME)
            FROM   INFORMATION_SCHEMA.TABLES
            WHERE  TABLE_TYPE = 'BASE TABLE'
                AND QUOTENAME(TABLE_NAME) > @TableName2
                AND OBJECTPROPERTY(
                        OBJECT_ID(
                            QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
                        ), 'IsMSShipped'
                    ) = 0
        )

        WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)
        BEGIN
            SET @ColumnName =
            (
                SELECT MIN(QUOTENAME(COLUMN_NAME))
                FROM   INFORMATION_SCHEMA.COLUMNS
                WHERE  TABLE_SCHEMA = PARSENAME(@TableName, 2)
                    AND TABLE_NAME  = PARSENAME(@TableName, 1)
                    AND DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar')
                    AND QUOTENAME(COLUMN_NAME) > @ColumnName
            )

            IF @ColumnName IS NOT NULL and (@TableName = '[dba].[defect]')
            BEGIN
                INSERT INTO #Results
                EXEC
                (
                    'SELECT ''' + @TableName + '.' + @ColumnName + ''', ID as Defect, LEFT(' + @ColumnName + ', 3630) FROM ' + @TableName + ' (NOLOCK) ' +
                    ' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
                )
/*
                if exists (select 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName2 and COLUMN_NAME = 'id')
                    begin
                    INSERT INTO #Results
                    EXEC
                    (
                        'SELECT ''' + @TableName + '.' + @ColumnName + ''', ID as Defect, LEFT(' + @ColumnName + ', 3630) FROM ' + @TableName + ' (NOLOCK) ' +
                        ' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
                    )
                    end
                else
                    begin
                    INSERT INTO #Results
                    EXEC
                    (
                        'SELECT ''' + @TableName + '.' + @ColumnName + ''', ''n/a'' as Defect, LEFT(' + @ColumnName + ', 3630) FROM ' + @TableName + ' (NOLOCK) ' +
                        ' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
                    )
                    end
*/
            END
        END
    END

    SELECT Defect, ColumnName, ColumnValue FROM #Results order by Defect, ColumnValue
END

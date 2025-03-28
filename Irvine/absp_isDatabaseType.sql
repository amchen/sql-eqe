if exists(select * from SYSOBJECTS where ID = object_id(N'absp_isDatabaseType') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_isDatabaseType
end
go

create procedure absp_isDatabaseType @dbName varchar(120) ,@dbType char(3) 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure check if a database has a certain DBType defined in RQEVersion, i.e. RDB, EDB, SYS, COM

Returns:       1 or 0.

=================================================================================
</pre>
</font>
##BD_END

##PD  dbName    ^^ databaseName
##PD  @dbType   ^^ the RQE DBType to check against.

##RS  @cnt    ^^ The count of 1 or 0.
*/
begin
declare @nsql nvarchar(max)
declare @cnt int

set @nsql = N'if exists (select 1 from [' + rtrim(@dbName) + '].sys.objects where type = ''U'' and name = ''RQEVersion'')' +
' select @cnt = count(*) from [' + rtrim(@dbname) + '].dbo.RQEVersion where dbType = ''' + @dbType + '''' + 
' else ' +
' select @cnt = 0'
exec sp_executesql @nsql, N'@cnt int OUTPUT', @cnt OUTPUT
select @cnt
end
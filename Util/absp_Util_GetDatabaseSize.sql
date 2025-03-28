if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetDatabaseSize') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetDatabaseSize
end
go

CREATE  procedure [dbo].[absp_Util_GetDatabaseSize]
	@dbName as varchar(120)
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose: This procedure calls sp_spaceused and returns the size information for the database.
====================================================================================================
</pre>
</font>
##BD_END

##PD	@dbName  ^^  Name of the database.
*/

declare @qry as nvarchar(max);
begin
	set @qry ='use ['+ltrim(rtrim(@dbName))+'] exec sp_spaceused ';
	--  print @qry;
	EXEC(@qry);
end
go

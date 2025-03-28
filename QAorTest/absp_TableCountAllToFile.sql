if EXISTS(SELECT * FROM sysobjects WHERE id = object_id(N'absp_TableCountAllToFile') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_TableCountAllToFile
end

GO

create procedure absp_TableCountAllToFile @dbName varchar(130), @outputPath varchar(1000), @userName varchar(1000)='' , @password varchar(1000)=''
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    SQL2005
Purpose:

	This procedure count up every table which is not a client side table and insert count into table and save the table to disk and drop the table.

Returns: Nothing
              
====================================================================================================

</pre>
</font>
##BD_END
 
##PD  fileName    ^^ This is the file where save the table.


*/
AS
begin
	begin try
		declare @count		int
		declare @cntTable	varchar(50)
		declare @sql		varchar(max)
		declare @DateStr	nvarchar(20)

		exec absp_Util_GetDateString	@cntTable output , 'yyyymmddhhnnss'
		set @cntTable = 'COUNT' + ltrim(rtrim(@cntTable))
		
		execute('create table '+@cntTable+'( tablename char(120), count int )')

		set @sql = ' insert  into ' + ltrim(rtrim(@cntTable))  + '
					select	dbo.trim(T2.name), rowcnt from ' +
							 dbo.trim(@dbName) + '..sysindexes T1, ' +
							 dbo.trim(@dbName) + '..sysobjects T2 ' +
							'where	T1.id = T2.id  ' +
							'and		T2.xtype = ''U''  ' +
							'and		T1.indid in (0,1) ' +
							'and		T2.name  IN (select TABLENAME as TN from ' +
							 dbo.trim(@dbName) + '..DICTTBL where LOCATION <> ''C'' ) ' +
							'order by T2.name '
		execute (@sql)
		exec absp_util_unloaddata 't', @cntTable, @outputPath
		 
		execute('drop table '+@cntTable)
	end try

	begin catch
		select error_line()as line_number, error_message()as error_message
	end catch
end;
   

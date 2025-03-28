if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_RenameTreeviewNodeName') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_RenameTreeviewNodeName
end
 go

create procedure absp_Util_RenameTreeviewNodeName @newStr char(10),@tagToReplace char(10) = '(ICMS)' 

/*
##BD_BEGIN
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will rename any node name that has matching tagToReplace string by 
replacing the matching string with the new string.It excludes those node names which 
does not have an INFO table.
This procedure will be used by the ICMS Unit test framework and the newStr will be the test id.

Returns: Nothing

====================================================================================================

</pre>
</font>
##BD_END

##PD  @newStr ^^ The string with which the procedure will replace the matching <tagToReplace> string.
##PD  @tagToReplace  ^^ The string which is to be replaced by the new string.

*/
as

begin

   set nocount on
   
   declare @origName varchar(120)
   declare @newName char(120)
   declare @sql varchar(255)
   declare @sql1 varchar(255)
   declare @me varchar(255)
   declare @msg varchar(255)
   declare @c1_tblName char(120)
   declare curs1  cursor dynamic local for select  rtrim(ltrim(tablename)) as table_name from dictcol where tablename like '%INFO%' and fieldname like 'LONGNAME%'
   set @me = 'absp_Util_RenameTreeviewNodeName'
   set @origName = ''
   set @newName = ''
   set @sql = ''
   set @msg = 'Starting...'
   execute absp_Util_Log_Info @msg,@me
   set @msg = 'Pass 1: Loop thru all XXXINFO table'
   execute absp_Util_Log_HighLevel @msg,@me
  -- Get all tables that ends with the INFO 
   open curs1
   fetch next from curs1 into @c1_tblName
   while @@fetch_status = 0
   begin
	 set @msg = 'Pass 2: Find all name that matchs the tag '''+ltrim(rtrim(@tagToReplace))+''' in table '+ltrim(rtrim(@c1_tblName))
	 execute absp_Util_Log_HighLevel @msg,@me
	 set @sql = 'select ltrim(rtrim(LONGNAME)) name from '+@c1_tblName+' where LONGNAME like ''%'+ltrim(rtrim(@tagToReplace))+'%'''
	 execute('declare curs2 cursor dynamic for '+@sql)
	 open curs2 
	 fetch next from curs2 into @origName
	 while @@fetch_status = 0
	 begin
		-- get each inur_key we need to clone
		-- replace tag
		select  @newName = replace(ltrim(rtrim(@origName)),ltrim(rtrim(@tagToReplace)),ltrim(rtrim(@newStr))) 
		set @msg = 'Orignal Name = '+ltrim(rtrim(@origName))+' changed to '+ltrim(rtrim(@newName))
		execute absp_Util_Log_Info @msg,@me
		set @sql1 = 'update '+@c1_tblName+' set LONGNAME = '''+ltrim(rtrim(@newName))+''' where current of curs2'
		execute absp_Util_Log_HighLevel @sql1,@me
		execute(@sql1)
		fetch next from curs2 into @origName
	end
	close curs2
	deallocate curs2
	fetch next from curs1 into @c1_tblName
   end
   close curs1
   deallocate curs1
   set @msg = 'Completed.'
   execute absp_Util_Log_Info @msg,@me
end


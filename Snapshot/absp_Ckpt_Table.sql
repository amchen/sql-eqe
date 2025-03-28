if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Ckpt_Table') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Ckpt_Table
end
 go

create procedure absp_Ckpt_Table @theTable char(120),@thePostfix char(50) 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a table with the same structure as the given base table 
and also populates it with the data same as that of the base table.


Returns:       Nothing.

=================================================================================
</pre>
</font>
##BD_END

##PD  @theTable     ^^ A string containing the base table name.
##PD  @thePostfix   ^^ An string value for the postfix.


*/
as

begin
 
   set nocount on
   
  declare @theCount int
   declare @maxCount int
   declare @MsgTxt varchar(255)
   declare @CrtTblTxt varchar(255)
   declare @sql nvarchar(4000)

   set @maxCount = 6000000 -- SDG__00015095 - set to 6 million
  -- start
   execute absp_MessageEx 'absp_Ckpt_Table - Started'

   select  @theCount = ROWCNT  from SYSINDEXES where object_name(ID) = @theTable and INDID<2;
   
   set @theCount = isnull(@theCount,0)
   if(@theCount < @maxCount)
	   begin
		  set @MsgTxt = 'Populating Snapshot Table '+@theTable+@thePostfix+' ('+rtrim(ltrim(str(@theCount)))+' records)'
		  execute absp_MessageEx @MsgTxt
		  execute absp_Migr_MakeCopyTable '',@thePostfix,'',@theTable
	   end
   else
	   begin
		  set @MsgTxt = 'Skipping Snapshot for Table '+@theTable+' ('+rtrim(ltrim(str(@theCount)))+' records)'
		  execute absp_MessageEx @MsgTxt
		  set @CrtTblTxt = ltrim(rtrim(@theTable)) + ltrim(rtrim(@thePostfix))
		  execute absp_Migr_CreateTable @theTable, @CrtTblTxt,0
	   end
   execute absp_MessageEx 'absp_Ckpt_Table - Done'

end




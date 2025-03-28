if exists(select 1 from sysobjects where ID = object_id(N'absp_UnloadTables') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_UnloadTables
end
go

create procedure absp_UnloadTables @theList varchar(max),@thePath char(255),@theDelimiter char(1) = ',',@display int = 1 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     SQL2005
Purpose:    	This procedure unloads each table which are listed in parameter theList to file based 
		on file which is specified in thePath.


Returns:    Nothing

====================================================================================================

</pre>
</font>

##BD_END

##PD  @theList  ^^ The list of the tablename.
##PD  @thePath  ^^ The path where records of tables will be unloaded.
##PD  @theDelimiter  ^^ The deleimiter used in theList to seperate the tablenames.
##PD  @display  ^^ The flag which is used to show mwssage or not.

*/
as
begin
   declare @len int
   declare @pos int
   declare @head int
   declare @tail int
   declare @ch char(2)
   declare @debug int
   declare @myList varchar(max)
   declare @strTabale varchar(max)
   declare @mode int
   declare @filePath char(255)
   declare @sql varchar(max)
   --set @debug = @displa
   execute absp_Util_Replace_Slash @filePath out, @thePath
   --set @myList = rtrim(ltrim(@theList))
   if left(@theList,1) <> @theDelimiter
   begin
      set @theList = @theDelimiter+@theList
   end
   if right(@theList,1) <> @theDelimiter
   begin
      set @theList = @theList+@theDelimiter
   end
   if @display > 0
   begin
      print getdate()
      print ' absp_UnloadTables: @myList = '+@theList
   end
   set @len = len(@theList)
   set @pos = 1
   set @mode = 0
   while(@pos <= @len)
   begin
      set @ch = substring(@theList,@pos,1)
      if(@ch = @theDelimiter)
      begin
         if(@mode = 0)
         begin
            set @pos = @pos+1
            set @head = @pos
            set @tail = 0
            set @mode = 1
         end
         else
         begin
            set @tail = @pos -@head
            set @strTabale = rtrim(ltrim(substring(@theList,@head,@tail)))
            if @debug > 0
            begin
               print getdate()
               print ' absp_UnloadTables: Table = '+@strTabale
            end
            set @sql = 'if exists ( select 1 from sysobjects where name = '''+@strTabale+''' and type = ''U'' ) '
            set @sql = @sql+'exec absp_Util_UnloadData  ''t'', '''+ltrim(rtrim(@strTabale))+''' ,'''+ltrim(rtrim(@thePath))+'\\'+ltrim(rtrim(@strTabale))+'.txt'', ''|''' 
            print @sql
            execute(@sql)
            set @mode = 0
         end
      end
      else
      begin
         set @pos = @pos+1
      end
   end
end


if exists(select * from SYSOBJECTS where ID = object_id(N'absp_QA_DeleteTreeview') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_QA_DeleteTreeview
end
go

create procedure absp_QA_DeleteTreeview 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       The procedure deletes the contents of the treeview except the default Currency Folder. 
               It deletes the contents of the xxxMAP tables and marks the xxxINFO tables for deletion.

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END 
*/
 
as
begin
	declare @tName varchar(120)
	declare @defaultCurrFldrKey int
		
	select @defaultCurrFldrKey = FOLDER_KEY from FLDRINFO 
	      where FOLDER_KEY = ( select min(FOLDER_KEY) from FLDRINFO where CURR_NODE='Y');
	
	-- Delete all MAP tables --
	declare curs1 cursor for
       select TABLENAME from dbo.absp_Util_GetTableList('Treeview.Map')
	open curs1
	fetch curs1 into @tName
	
	while @@fetch_status=0
    begin

    	print @tName

    	-- Exclude the map for the default Currency Folder --
    	if @tName = 'FLDRMAP'
    		DELETE FROM FLDRMAP where NOT (CHILD_KEY = @defaultCurrFldrKey and CHILD_TYPE = 0)

        -- Mark FLDRINFO records as DELETED except for the default Currency Folder--
	else if @tName = 'FLDRINFO'
		DELETE FROM FLDRINFO where FOLDER_KEY > @defaultCurrFldrKey

	else
		execute('DELETE  FROM ' + @tName)
		
		fetch curs1 into @tName
	end
	close curs1
	deallocate curs1

  	-- Mark INFO table records as deleted --
	declare curs2 cursor for
       select TABLENAME from dbo.absp_Util_GetTableList('Portfolio.Info')
	open curs2
	fetch curs2 into @tName
	while @@fetch_status=0
    begin
    	print @tName

          execute ('UPDATE  ' +  @tName +' SET STATUS=''DELETED''')
        fetch curs2 into @tName
	end
	close curs2
	deallocate curs2
end

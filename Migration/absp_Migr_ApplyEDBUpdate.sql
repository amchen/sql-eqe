if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_ApplyEDBUpdate') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_ApplyEDBUpdate
end
go

create procedure absp_Migr_ApplyEDBUpdate

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure applies update instructions,to all attached EDB and IDB databases.
Returns:	Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @dbType ^^ The dbType (SYS, COM, EDB, IDB, RDB)
##PD  @dbName ^^ The name of the database to apply the update
*/

as

begin
	set nocount on;

	declare @sql varchar(max);			-- statements we execute
	declare @dbName varchar(120);
	
	--Get all attached EDB databases--
	declare curs cursor fast_forward  for select distinct DB_NAME from CFLDRINFO
	open curs
	fetch next from curs into @dbName;
	while @@fetch_status = 0
	begin
		exec absp_Migr_ApplyUpdate 'EDB', @dbName
		set @dbName = @dbName + '_IR'
		exec absp_Migr_ApplyUpdate 'IDB', @dbName	
		fetch next from curs into @dbName;
	end
	close curs;
	deallocate curs;
end;

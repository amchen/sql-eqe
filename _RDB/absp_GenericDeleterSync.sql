if exists ( select 1 from sysobjects where name = 'absp_GenericDeleterSync ' and type = 'P' )
begin
   drop procedure absp_GenericDeleterSync;
end
go

create procedure absp_GenericDeleterSync
	@infoTable varchar(120),
	@infoColumn varchar(120),
	@infoKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose: This procedure syncs the xxxxInfo table between EDB and IDB so that the absp_GenericDeleter
		 can properly deleted the records on the IDB database.
Returns: Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  @infoTable  ^^ The xxxxInfo table name.
##PD  @infoColumn ^^ The xxxxInfo column name.
##PD  @infoKey    ^^ The xxxxInfo key value.
*/
as
begin try
	declare @sql varchar(2000);
	declare @dbName varchar(255);

	------------------- IDB side --------------------------------
	if exists(select 1 from RQEVersion where DbType = 'IDB')
	begin
		set @sql = 'if not exists (select 1 from @infoTable where @infoColumn=@infoKey) begin ';
		set @sql = @sql + 'set identity_insert @infoTable on;';
		set @sql = @sql + 'insert @infoTable(@infoColumn,Status) values (@infoKey,''DELETED'');';
		set @sql = @sql + 'set identity_insert @infoTable off; end;';
	end
	else
	begin
	------------------- EDB side --------------------------------
		select @dbName = DB_NAME() + '_IR';
		set @sql = 'exec [@dbName]..absp_GenericDeleterSync ''@infoTable'',''@infoColumn'',@infoKey';
		set @sql = replace(@sql,'@dbName',@dbName);
	end
	set @sql = replace(@sql,'@infoTable',@infoTable);
	set @sql = replace(@sql,'@infoColumn',@infoColumn);
	set @sql = replace(@sql,'@infoKey',cast(@infoKey as varchar(30)));
	execute(@sql);
end try

-- Catch all exceptions since this is run again by the background deleter job
begin catch

end catch

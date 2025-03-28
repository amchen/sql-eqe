if exists(select 1 from SYSOBJECTS where id = object_id(N'absp_UnloadSysCatalogs') and objectproperty(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_UnloadSysCatalogs;
end
go

create procedure absp_UnloadSysCatalogs @query varchar(max)='', @bcpQuery varchar(8000), @filePath varchar(1000),@catalogType varchar(20),@excludeTableList varchar(max)
as
/*
====================================================================================================
Purpose:

This procedure unloads the system catalogs in individual text files

Returns: zero on success, non-zero on failure
====================================================================================================
*/

begin
	declare @sql varchar(max);
	declare @sSql varchar(max);
	declare @catalogName varchar(200);
	declare @catlogDef varchar(max);
	declare @sqlUnloadStmt varchar(8000);
	declare @retcode int;

	--create outpath
	set @filePath = @filePath + '\' + @catalogType
	exec  absp_Util_CreateFolder @filePath

	if len(@excludeTableList) >0
		set @query = @query + ' and Name not in (' + @excludeTableList + ')';

	set @sql='declare CursSysCatalog cursor fast_forward global for ' + @query;
	exec(@sql);

	open CursSysCatalog;
	fetch next from CursSysCatalog into @catalogName, @catlogDef;
	while @@FETCH_STATUS=0
	begin
		set @sqlUnloadStmt =replace(@bcpQuery,'@filePath',@filePath +'\\' + @catalogName + '.txt');
		set @query = replace(@query, 'select Name, Definition from', 'select Definition from');
		set @sqlUnloadStmt =replace(@sqlUnloadStmt,'@sqlUnloadStmt',@query + ' where NAME=''' + @catalogName + '''');
		print @sqlUnloadStmt;
		exec xp_cmdshell @sqlUnloadStmt,no_output;

		fetch next from CursSysCatalog into @catalogName, @catlogDef;
	end
	close CursSysCatalog;
	deallocate CursSysCatalog;
end

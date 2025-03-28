if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CreateDictViewViews') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateDictViewViews;
end
go

create procedure absp_Util_CreateDictViewViews

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:		SQL2008
Purpose:		This procedure will create the view in DictViews

Example call:	exec absp_Util_CreateDictViewViews

Returns:		Nothing
====================================================================================================
</pre>
</font>
##BD_END

*/
as
begin
	-- Only create these views in EDB/IDB
	if exists (select 1 from RQEVersion where DbType in ('EDB','IDB'))
	begin
		declare @viewName nvarchar(max);
		declare @viewSql nvarchar(max);
		declare @sql nvarchar(max);

		declare cursCreateDictViewViews cursor for
		select ViewName, ViewSql from systemdb..DictView order by DictViewRowNum;
		open cursCreateDictViewViews;
		fetch next from cursCreateDictViewViews into @viewName, @viewSql;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			--print @viewName + '\t' +@viewSql;
			set @sql ='IF OBJECT_ID(''~~~'', ''V'') IS NOT NULL DROP VIEW ~~~;';
			set @sql = REPLACE(@sql, '~~~', rtrim(@viewName));
			--print @sql;
			exec sp_executesql @sql;
			set @sql = 'create view ' + rtrim(@viewName) + ' as ' + @viewSql;
			--print @sql;
			exec sp_executesql @sql;

			fetch next from cursCreateDictViewViews into @viewName, @viewSql;
		end
		close cursCreateDictViewViews;
		deallocate cursCreateDictViewViews;
	end
end

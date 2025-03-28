if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CleanupSchema') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_CleanupSchema;
end
go

create procedure  absp_Util_CleanupSchema @schemaName varchar(200)
as
/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure drops all objects of the given schema before dropping the schema itself.
Returns:	Nothing

====================================================================================================
</pre>
</font>
##PD  @schemaName ^^ The schema that is to be cleaned up
##BD_END
*/
begin

declare @schema varchar(200)
declare @curs1 cursor
declare @sqlQuery varchar(max)

-- Make sure @schemaName exists
if not exists (select 1 from sys.schemas where name = @schemaName )
	return;

set @schema = @schemaName

print 'dropping ' + @schema

set @curs1 = cursor fast_forward for
		select
		'DROP ' + case
			when o.xtype = 'U' then 'TABLE'
			when o.xtype = 'V' then 'VIEW'
			when o.xtype = 'P' then 'PROCEDURE'
			when o.xtype = 'FN' then 'FUNCTION'
			end + ' ' + s.name + '.' + o.name as SQL
		from
			sys.sysobjects as o
			join sys.schemas as s on o.uid = s.schema_id
		where
			s.name = @schema and
			o.xtype in ('U','V','P','FN')
		union all
		select
		'DROP SCHEMA ' + @schema

open @curs1
fetch next from @curs1 into @sqlQuery
while @@fetch_status = 0
begin
	begin try
		exec (@sqlQuery)
	end try
	begin catch
		--if the object has already been dropped by another session
	end catch
	fetch next from @curs1 into @sqlQuery
end
close @curs1
deallocate @curs1

end

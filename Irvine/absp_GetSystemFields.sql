if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetSystemFields') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetSystemFields;
end
go

create procedure dbo.absp_GetSystemFields
	@ret_fieldNames varchar(max) output,
	@myTableName varchar(200)
/*
====================================================================================================
Purpose: This procedure will return the column names of a given table name,
		 as comma separated values from the system table.
====================================================================================================
*/
as
begin

	set nocount on;

	declare @sSql    varchar(max);
	declare @fldName varchar(200);
	declare @objid   int;

	select @objid = Object_ID(@myTableName);

	set @fldName = '';
	set @ret_fieldNames = ' ';

	create table #Table_Desc(
		FieldName       varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS,
		Data_Type 		varchar(50)  COLLATE SQL_Latin1_General_CP1_CI_AS,
		Length 			int,
		Column_Id 		int);

	-- Find Column Description --
	insert into #Table_Desc
		select
			'FieldName'	= name,
			'Type'		= type_name(user_type_id),
			'Length'	= convert(int, max_length),
			Column_Id
		from sys.all_columns where object_id = @objid order by Column_Id;

	declare curs_fldName cursor local for
		select FieldName from #Table_Desc order by Column_Id;
    open curs_fldName;
    fetch next from curs_fldName into @fldName;
	while @@fetch_status = 0
	begin
		set @ret_fieldNames = @ret_fieldNames + ', ' + ltrim(rtrim(@fldName));
		fetch next from curs_fldName into @fldName;
	end
	close curs_fldName;
	deallocate curs_fldName;

	if len(@ret_fieldNames) > 3
		set @ret_fieldNames = substring(@ret_fieldNames, 4, len(@ret_fieldNames) - 3);

end

if exists(select 1 from sysobjects where ID = object_id(N'absp_Util_CreateLookupViews') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateLookupViews;
end
go

create procedure absp_Util_CreateLookupViews

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:    This procedure creates joined views to the Lookup tables.
Returns:    None
====================================================================================================
</pre>
</font>
##BD_END
*/

as
begin

	set nocount on;

	declare @list varchar(max);
	declare @str1 varchar(max);
	declare @str2 varchar(max);
	declare @str3 varchar(max);
	declare @str4 varchar(max);
	declare @str  varchar(max);
	declare @sql  varchar(max);
	declare @dbName varchar(4);

	set @dbName = left(DB_NAME(),4);

	if exists (select 1 from RQEVersion where DbType in ('EDB','IDB'))
	begin
		set @dbName='Base';
	end

	-- Make sure we are in User database
	if (@dbName='Base')
	begin

		-- StructureType
		if exists (select 1 from sys.views where name='StructureType' and type='V')
		begin
			drop view StructureType;
		end

		-- Country_ID,Str_Eq_ID,Trans_ID,User_Eq_ID,Region,Comp_Descr,Story_Min,Story_Max,Str_Type_1,Str_Prct_1,
		-- Str_Type_2,Str_Prct_2,Str_Type_3,Str_Prct_3,Str_Type_4,Str_Prct_4,Str_Type_5,Str_Prct_5,In_List,Dflt_Row
		exec absp_Util_GetColumnList @list output, 'ESDL';
		set @list = replace(@list,'User_Eq_ID','User_Eq_ID as User_ID');
		set @str1 = replace(@list,'Str_Eq_ID','Str_Eq_ID as Str_ID') + ',''EQ'' as PerilType from ESDL';

		-- Country_ID,Str_Ws_ID,Trans_ID,User_Ws_ID,Region,Comp_Descr,Story_Min,Story_Max,Str_Type_1,Str_Prct_1,
		-- Str_Type_2,Str_Prct_2,Str_Type_3,Str_Prct_3,Str_Type_4,Str_Prct_4,Str_Type_5,Str_Prct_5,In_List,Dflt_Row
		exec absp_Util_GetColumnList @list output, 'WSDL';
		set @list = replace(@list,'User_Ws_ID','User_Ws_ID as User_ID');
		set @str2 = replace(@list,'Str_Ws_ID','Str_Ws_ID as Str_ID') + ',''WS'' as PerilType from WSDL';

		-- Country_ID,Str_Fd_ID,Trans_ID,User_Fd_ID,Region,Comp_Descr,Story_Min,Story_Max,Str_Type_1,Str_Prct_1,
		-- Str_Type_2,Str_Prct_2,Str_Type_3,Str_Prct_3,Str_Type_4,Str_Prct_4,Str_Type_5,Str_Prct_5,In_List,Dflt_Row
		exec absp_Util_GetColumnList @list output, 'FSDL';
		set @list = replace(@list,'User_Fd_ID','User_Fd_ID as User_ID');
		set @str3 = replace(@list,'Str_Fd_ID','Str_Fd_ID as Str_ID') + ',''FD'' as PerilType from FSDL';

		set @str = 'create view StructureType as select @str1 union all select @str2 union all select @str3';
		set @str = replace(@str, '@str1', @str1);
		set @str = replace(@str, '@str2', @str2);
		set @sql = replace(@str, '@str3', @str3);

		print @sql;
		exec(@sql);

		-- OccupancyType
		if exists (select 1 from sys.views where name='OccupancyType' and type='V')
		begin
			drop view OccupancyType;
		end

		-- Country_ID,E_Occpy_ID,E_Occpy_No,Trans_ID,U_E_Oc_ID,E_Occ_Desc,In_List,Dflt_Row,RiskTypeID,RiskType
		exec absp_Util_GetColumnList @list output, 'EOTDL';
		set @list = replace(@list,'E_Occpy_ID','E_Occpy_ID as Occpy_ID');
		set @list = replace(@list,'E_Occpy_No','E_Occpy_No as Occpy_No');
		set @list = replace(@list,'U_E_Oc_ID', 'U_E_Oc_ID  as User_ID');
		set @str1 = replace(@list,'E_Occ_Desc','E_Occ_Desc as User_Desc') + ',''EQ'' as PerilType from EOTDL';

		-- Country_ID,W_Occpy_ID,W_Occpy_No,Trans_ID,U_W_Oc_ID,W_Occ_Desc,In_List,Dflt_Row,RiskTypeID,RiskType
		exec absp_Util_GetColumnList @list output, 'WOTDL';
		set @list = replace(@list,'W_Occpy_ID','W_Occpy_ID as Occpy_ID');
		set @list = replace(@list,'W_Occpy_No','W_Occpy_No as Occpy_No');
		set @list = replace(@list,'U_W_Oc_ID', 'U_W_Oc_ID  as User_ID');
		set @str2 = replace(@list,'W_Occ_Desc','W_Occ_Desc as User_Desc') + ',''WS'' as PerilType from WOTDL';

		-- Country_ID,F_Occpy_ID,F_Occpy_No,Trans_ID,U_F_Oc_ID,F_Occ_Desc,In_List,Dflt_Row,RiskTypeID,RiskType
		exec absp_Util_GetColumnList @list output, 'FOTDL';
		set @list = replace(@list,'F_Occpy_ID','F_Occpy_ID as Occpy_ID');
		set @list = replace(@list,'F_Occpy_No','F_Occpy_No as Occpy_No');
		set @list = replace(@list,'U_F_Oc_ID', 'U_F_Oc_ID  as User_ID');
		set @str3 = replace(@list,'F_Occ_Desc','F_Occ_Desc as User_Desc') + ',''FD'' as PerilType from FOTDL';

		set @str = 'create view OccupancyType as select @str1 union all select @str2 union all select @str3';
		set @str = replace(@str, '@str1', @str1);
		set @str = replace(@str, '@str2', @str2);
		set @sql = replace(@str, '@str3', @str3);

		print @sql;
		exec(@sql);

	end
end

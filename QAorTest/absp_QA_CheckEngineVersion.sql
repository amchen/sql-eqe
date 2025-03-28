if exists(select 1 from SYSOBJECTS where id = object_id(N'absp_QA_CheckEngineVersion') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure absp_QA_CheckEngineVersion;
end
go

create procedure absp_QA_CheckEngineVersion
as
begin

    set nocount on;

	declare @Server_Name VARCHAR (20);
	declare @Eng_Name VARCHAR (120);
	declare @Analysis_Build_Num VARCHAR (20);
	declare @Import_Build_Num VARCHAR (20);

	set @Analysis_Build_Num = '16.00.00.754';
	set @Import_Build_Num = '16.00.00.340';

	if exists (select 1 from commondb..EngVer where Build_Num not in ('','@(#)BUILDNUMBER',@Analysis_Build_Num,@Import_Build_Num))
	begin
		select 'The following RQE servers have older Engine versions.' as Message;
		select Server_Name, Eng_Name, Build_Num, Build_Date, File_Size, File_Date from commondb..EngVer
			where Build_Num not in ('','@(#)BUILDNUMBER',@Analysis_Build_Num,@Import_Build_Num);
	end
	else
	begin
		select 'All RQE servers have the correct Engine versions.' as Message;
	end
end

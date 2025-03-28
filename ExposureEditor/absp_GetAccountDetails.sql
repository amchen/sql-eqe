if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetAccountDetails') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetAccountDetails
end
 go

create procedure absp_GetAccountDetails @exposureKey int, @accountKey int, @nodeKey int, @nodeType int, @financialModelType int,@userKey int=1,@debug int=0						
as
begin
	set nocount on
	
	declare @tableName varchar(120);
	declare @sql nvarchar(max);
	declare @attrib int;
	declare @tableExists int;
	declare @InProgress int;	
	
	exec @InProgress=absp_IsDataGenerationInProgress @nodeKey,@nodeType
	if @InProgress=1 
	begin
		select T1.*, '','','',0 from Reinsurance T1 where 1=0;  
		return;
	end
	
	--Reurn Account Rein--
	set @tableName='FilteredAccountReinsurance_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	set @sql = 'select @tableExists= 1 from sys.objects where object_id = OBJECT_ID(N''[dbo].[' + @tableName + ']'') AND type in (N''U'')' 
	exec sp_executesql @sql,N'@tableExists int out' ,@tableExists out 

	exec absp_InfoTableAttribGetBrowserDataRegenerate  @attrib out,@nodeType,@nodeKey
	if @attrib=0 and @tableExists=1
	begin

		set @sql = 'select distinct T1.*,AccountNumber,R.Name as ReinsurerName, T.Name  as TreatyTagName,RowNum from Reinsurance T1 inner join ' + @tableName + ' T2 
				on T1.ReinsuranceRowNum=T2.ReinsuranceRowNum 
				 inner join Reinsurer R on T1.ReinsurerID=R.ReinsurerID 
				  inner join TreatyTag T on T1.TreatyTagID=T.TreatyTagID 
				where T1.ExposureKey=' + cast(@exposureKey as varchar(30)) + ' and T1.AccountKey =' + cast(@accountKey as varchar(30));
		set @sql = @sql + ' order by RowNum'
		exec absp_MessageEx @sql
		exec(@sql)
	end
	else
	begin
		--BrowserData needs to be regenerated--
		select T1.*, '','','',0 from Reinsurance T1 where 1=0; 
		
		
	end
end
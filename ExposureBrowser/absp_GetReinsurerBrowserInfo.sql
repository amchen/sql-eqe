if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetReinsurerBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetReinsurerBrowserInfo
end
go

create  procedure absp_GetReinsurerBrowserInfo  @nodeKey int, 
					     @nodeType int, 
					     @exposureKey int =-1, 
					     @accountKey int=-1,
					     @sessionID int,
					     @whereClause varchar(8000)='',
					     @orderByClause varchar(8000)='',
					     @pageNum int=1, 
					     @pageSize int=500,
					     @createTempTable int=1
					     
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose: The procedure will get the summary information from the Reinsurer table 
for the given Pport/Program or Exposure.The resultset will be limited by the page size.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey  ^^ The node for which the account summary information is to be fetched.
##PD  @nodeType  ^^ The node type for which the account summary information is to be fetched.
##PD  @exposureKey  ^^ The exposureKey for which the account summary information is to be fetched.
##PD  @accountKey  ^^ The account for which the account summary information is to be fetched.
##PD  @whereClause  ^^ The where clause
##PD  @orderByClause  ^^ The order by clause
##PD  @pageNum  ^^ The page that is to be returned.
##PD  @pageSize  ^^ The size of the page.

*/
as
begin
BEGIN TRY
 
	set nocount on;
	declare @sql varchar(max);
	declare @RowCntSql varchar(max);		
	declare @startRowNum int;
	declare @endRowNum int;
	declare @tRows int;
	declare @debug int;
	declare @tmpTbl varchar(50)
	declare @tmpCntTbl varchar(50)
	declare @BrowserDataStatus varchar(50)
	declare @financialModelType smallint

	set @debug = 0;
	set @tRows= 20000;
	set @tmpTbl='TMP_REIN_SUMMARY' + dbo.trim(cast(@sessionId as varchar(50)))
	set @tmpCntTbl='TMP_REIN_SUMMARY_CNT' + dbo.trim(cast(@sessionId as varchar(50)))

	if @debug=1 exec absp_MessageEx  'Begin absp_GetReinsurerBrowserInfo'
	
	--Since we do not have any browserInfo table for reinsurance
	--we need to keep checks for the displayed columns
	if @orderByClause='TreatyTypeDisplayName' set @orderByClause='9'
	if @orderByClause='TreatyTagDisplayName' set @orderByClause='10'
	if @orderByClause='PerilDisplayName' set @orderByClause='13'
	if @orderByClause='CoverageDisplayName' set @orderByClause='14'
	if @orderByClause='ReinsurerDisplayName' set @orderByClause='19'
	if @orderByClause='' set @orderByClause='AccountNumber, PolicyNumber'
	
	if charindex( 'treatyTagDisplayName',@whereClause)>0
	begin
		if charindex( '''''',@whereClause)>0
		begin
			set @whereClause =REPLACE(@whereClause,'treatyTagDisplayName','TreatyType')
			set @whereClause =REPLACE(@whereClause,'''''','F')
		end
		else
		begin
			set @whereClause =REPLACE(@whereClause,'treatyTagDisplayName','E.Name')
		end
	end
	 
	if charindex( 'TreatyTypeDisplayName',@whereClause)>0
	begin
		set @whereClause =REPLACE(@whereClause,'TreatyTypeDisplayName','TreatyType')
		set @whereClause =REPLACE(@whereClause,'Facultative Treaty','F')
		set @whereClause =REPLACE(@whereClause,'Reinsurance Treaty','T')
	end	
	 
	set @whereClause =REPLACE(@whereClause,'CoverageDisplayName','G.U_COV_NAME')
	set @whereClause =REPLACE(@whereClause,'ReinsurerDisplayName','H.Name')

	set @startRowNum = ((@pageNum - 1) * @pageSize) + 1
	set @endRowNum = @pageNum * @pageSize 

	--Create temporary table only when required--
	if @createTempTable=1
	begin
		--Create temp table--
		if exists(select 1 from sys.tables where name=@tmpTbl)
			exec('drop Table ' + @tmpTbl)
	end
	
	--Get the status of BrowserataGen--
	if @nodeType=4
		exec absp_CheckExposureBrowserInfoStatus @BrowserDataStatus out, -1,-1,@exposureKey
	else
		exec absp_CheckExposureBrowserInfoStatus @BrowserDataStatus out, @nodeKey,@nodeType
	
	--Create and populate table if table does not exist--
	if not exists(select 1 from sys.tables where name=@tmpTbl)
	begin
		set @sql='create table ' + @tmpTbl +
		'(ReinsuranceRowNum int identity(1,1), AppliesTo varchar(10) default '''', ExposureKey int ,AccountKey int ,PolicyKey int ,SiteKey int,
		AccountNumber varchar(50), PolicyNumber  varchar(50),SiteNumber  varchar(50),TreatyTypeDisplayName  varchar(50), TreatyTagDisplayName  varchar(75), 
		Certificate varchar(50),LayerNumber smallint,PerilDisplayName  varchar(35),CoverageDisplayName  varchar(50),CurrencyCode varchar(3),AttachmentPoint float,LayerAmount float,CededPct float,
		ReinsurerDisplayName  varchar(75), FinancialModelType smallint)'
		exec (@sql)
		

		if @debug=1 exec absp_MessageEx  'Created temporary table'
		
		if @BrowserDataStatus='Available'
		begin
			--Get all exposure Keys for PPort/Program--
			if @nodeType = 2 or @nodeType = 7 or @nodeType = 27
			begin
				--create temp table to hold the ExposureKeys--
				if OBJECT_ID('tempdb..#TMP_EXP','u') is not null drop table #TMP_EXP
				select ExposureMap.ExposureKey,FinancialModelType into #TMP_EXP from ExposureMap 
					inner join ExposureInfo on ExposureMap.ExposureKey=ExposureInfo.ExposureKey
					where ParentKey= @nodeKey and ParentType=@nodeType;
				create index #TMP_EXP_i1 on #TMP_EXP(ExposureKey)

				--Create view for Site and insert ID 0 so the join is successful
				if exists(select 1 from SYSOBJECTS where ID = object_id(N'VwSite') and objectproperty(id,N'IsView') = 1)   drop view VwSite
				set @sql = 'create view VwSite as select A.ExposureKey,AccountKey,SiteKey,SiteNumber from Site A, ExposureMap B where a.ExposureKey=B.ExposureKey and  ParentKey= ' + cast(@nodeKey as varchar) + ' and ParentType= ' + cast(@nodeType as varchar) +
						' union select A.Exposurekey,AccountKey,0,'''' from Site A, ExposureMap B where a.ExposureKey=B.ExposureKey and  ParentKey= ' + cast(@nodeKey as varchar) + ' and ParentType= ' +cast(@nodeType as varchar) 

				execute(@sql)
				
				--Create view for policy and insert ID 0 so the join is successful
				if exists(select 1 from SYSOBJECTS where ID = object_id(N'VwPol') and objectproperty(id,N'IsView') = 1)   drop view VwPol
				set @sql = 'create view VwPol as select A.ExposureKey,AccountKey,PolicyKey, PolicyNumber from Policy A, ExposureMap B where a.ExposureKey=B.ExposureKey and  ParentKey= ' + cast(@nodeKey as varchar) + ' and ParentType= ' + cast(@nodeType as varchar) +
						' union select A.ExposureKey,AccountKey,0,'''' from Policy  A, ExposureMap B where a.ExposureKey=B.ExposureKey and  ParentKey= ' + cast(@nodeKey as varchar) + ' and ParentType= ' +cast(@nodeType as varchar) 

				execute(@sql)

				--Get Rows into temp table--
				set @sql = 'insert into ' + @tmpTbl + 
					' (AppliesTo,ExposureKey,AccountKey,PolicyKey,SiteKey,AccountNumber, PolicyNumber,SiteNumber,TreatyTypeDisplayName, TreatyTagDisplayName, 
					Certificate,LayerNumber,PerilDisplayName,CoverageDisplayName,CurrencyCode,AttachmentPoint,LayerAmount,CededPct,ReinsurerDisplayName,FinancialModelType)
					select top (' + dbo.trim(cast(@tRows as varchar)) + ') case when A.SiteKey > 0 then ''Site'' else ''Policy'' end, A.ExposureKey,A.AccountKey,A.PolicyKey,A.SiteKey,AccountNumber,PolicyNumber,SiteNumber,
					case when TreatyType=''F'' then ''Facultative'' else ''Reinsurance Treaty'' end ,
					case when TreatyType=''F'' then '''' else E.Name end,
					Certificate,LayerNumber,F.PerilDisplayName,G.U_COV_NAME,
					A.CurrencyCode,AttachmentPoint,LayerAmount,CededPct,H.Name,T2.FinancialModelType
					from Reinsurance A 
					inner join Account B on A.ExposureKey = B.ExposureKey and A.AccountKey = B.AccountKey
					inner join VwPol C on A.ExposureKey = C.ExposureKey and A.AccountKey = C.AccountKey and A.PolicyKey = C.PolicyKey
					inner join VwSite D on A.ExposureKey = D.ExposureKey and A.AccountKey = D.AccountKey and A.SiteKey = D.SiteKey
					inner join TreatyTag E on A.TreatyTagID= E.TreatyTagID
					inner join Ptl F on A.PerilID= F.Peril_ID and F.Trans_Id in(66,67)
					inner join Cil G on  A.CoverageID = G.COVER_ID
					inner join Reinsurer H on A.ReinsurerID=H.ReinsurerID
					inner join  #TMP_EXP T2  on A.ExposureKey=T2.ExposureKey';

				set @RowCntSql='select count(*) as CNT into ' + @tmpCntTbl +' from Reinsurance A 
					inner join Account B on A.ExposureKey = B.ExposureKey and A.AccountKey = B.AccountKey
					inner join VwPol C on A.ExposureKey = C.ExposureKey and A.AccountKey = C.AccountKey and A.PolicyKey = C.PolicyKey
					inner join VwSite D on A.AccountKey = D.AccountKey and A.SiteKey = D.SiteKey
					inner join TreatyTag E on A.TreatyTagID= E.TreatyTagID
					inner join Ptl F on A.PerilID= F.Peril_ID and F.Trans_Id in(66,67)
					inner join Cil G on  A.CoverageID = G.COVER_ID
					inner join Reinsurer H on A.ReinsurerID=H.ReinsurerID
					inner join  #TMP_EXP T2  on A.ExposureKey=T2.ExposureKey';


			end
			else if @nodeType = 4 --NodeKey is AccountKey
			begin	
				--Get FinancialModelType for the exposure--
				select @financialModelType = FinancialModelType from ExposureInfo where ExposureKey=@exposureKey
					
				--Create view for Site and insert ID 0 so the join is successful
				if exists(select 1 from SYSOBJECTS where ID = object_id(N'VwSite') and objectproperty(id,N'IsView') = 1)   drop view VwSite
				set @sql = 'create view VwSite as select ExposureKey,AccountKey,SiteKey,SiteNumber from Site where ExposureKey=' + cast(@exposureKey as varchar) + 
						' union select ExposureKey,AccountKey,0,'''' from Site where ExposureKey=' + cast(@exposureKey as varchar) 
				execute(@sql)
				--Create view for Policy and insert ID 0 so the join is successful
				if exists(select 1 from SYSOBJECTS where ID = object_id(N'VwPol') and objectproperty(id,N'IsView') = 1)   drop view VwPol
				set @sql = 'create view VwPol as select ExposureKey,AccountKey,PolicyKey,PolicyNumber from policy where ExposureKey=' + cast(@exposureKey as varchar) + 
						' union select ExposureKey,AccountKey,0,'''' from policy where ExposureKey=' + cast(@exposureKey as varchar) 
				execute(@sql)

				--Get Rows into temp table--
				set @sql = 'insert into ' + @tmpTbl + 
					' (AppliesTo, ExposureKey,AccountKey,PolicyKey,SiteKey,AccountNumber, PolicyNumber,SiteNumber,TreatyTypeDisplayName, TreatyTagDisplayName, 
					Certificate,LayerNumber,PerilDisplayName,CoverageDisplayName,CurrencyCode,AttachmentPoint,LayerAmount,CededPct,ReinsurerDisplayName, FinancialModelType)
				    select top (' + dbo.trim(cast(@tRows as varchar)) + ') case when A.SiteKey > 0 then ''Site'' else ''Policy'' end, A.ExposureKey,A.AccountKey,A.PolicyKey,A.SiteKey,AccountNumber,PolicyNumber,SiteNumber,
					case when TreatyType=''F'' then ''Facultative'' else ''Reinsurance Treaty'' end ,
					case when TreatyType=''F'' then '''' else E.Name end,
					Certificate,LayerNumber,F.PerilDisplayName,G.U_COV_NAME,
					A.CurrencyCode,AttachmentPoint,LayerAmount,CededPct,H.Name, ' + cast(@financialModelType as varchar) + '
					from reinsurance A 
					inner join Account B on A.ExposureKey = B.ExposureKey and A.AccountKey = B.AccountKey
					inner join VwPol C on A.ExposureKey = C.ExposureKey and A.AccountKey = C.AccountKey and A.PolicyKey = C.PolicyKey
					inner join VwSite D on A.ExposureKey = D.ExposureKey and A.AccountKey = D.AccountKey and A.SiteKey = D.SiteKey
					inner join TreatyTag E on A.TreatyTagID= E.TreatyTagID
					inner join Ptl F on A.PerilID= F.Peril_ID and F.Trans_Id in(66,67)
					inner join Cil G on  A.CoverageID = G.COVER_ID
					inner join Reinsurer H on A.ReinsurerID=H.ReinsurerID ' +
					' where A.ExposureKey = ' + cast(@exposureKey as varchar) + 
					' and A.AccountKey= ' + cast(@nodeKey	as varchar) 

				set @RowCntSql='select count(*) as CNT into ' + @tmpCntTbl + ' from Reinsurance A 
					inner join Account B on A.ExposureKey = B.ExposureKey and A.AccountKey = B.AccountKey
					inner join VwPol C on A.ExposureKey = C.ExposureKey and A.AccountKey = C.AccountKey and A.PolicyKey = C.PolicyKey
					inner join VwSite D on A.AccountKey = D.AccountKey and A.SiteKey = D.SiteKey
					inner join TreatyTag E on A.TreatyTagID= E.TreatyTagID
					inner join Ptl F on A.PerilID= F.Peril_ID and F.Trans_Id in(66,67)
					inner join Cil G on  A.CoverageID = G.COVER_ID
					inner join Reinsurer H on A.ReinsurerID=H.ReinsurerID ' +
					' where A.ExposureKey = ' + cast(@exposureKey as varchar) + 
					' and A.AccountKey= ' + cast(@nodeKey	as varchar) 

			end
			else
				return --Incorrect nodeType

			--Add where clause
			if @whereClause<>''
			begin
				set @sql = @sql + ' and ' + @whereClause
				set @RowCntSql = @RowCntSql + ' and ' + @whereClause
			end

			--Add order by clause
			if @orderByClause<>''
				set @sql = @sql + ' order by ' + @orderByClause
			if @debug=1 exec absp_MessageEx  @sql	
			exec (@sql);
			if @debug=1 exec absp_MessageEx  'Populated temporary table'

			--Drop table to hold rowcount
			if exists(select 1 from sys.tables where name=@tmpCntTbl)
				exec('drop Table ' + @tmpCntTbl)

			--Populate TMP_REIN_SUMMARY_CNT
			if @debug=1 exec absp_MessageEx  @RowCntSql
			exec(@RowCntSql);

			
		end
	end
	
	--First resultset will contain the info to be displayed--
	set @sql ='select AppliesTo,ExposureKey,AccountKey,PolicyKey,SiteKey,AccountNumber, PolicyNumber,SiteNumber,TreatyTypeDisplayName, 
				TreatyTagDisplayName, Certificate,LayerNumber,PerilDisplayName,CoverageDisplayName,CurrencyCode,AttachmentPoint,LayerAmount,CededPct,
				ReinsurerDisplayName,FinancialModelType
	from ' + @tmpTbl + ' where ReinsuranceRowNum between ' + cast(@startRowNum as varchar) + ' and ' + cast(@endRowNum as varchar) + ' OPTION(RECOMPILE)'
	exec(@sql)
	if @debug=1 exec absp_MessageEx  'Returned first resultset'

	--Second recordset will return the record count--
	if @BrowserDataStatus='Available'
		exec('select CNT from ' + @tmpCntTbl)
	else
		select 0
	if @debug=1 exec absp_MessageEx  'Returned second resultset'

	--Third resultset will returnthe no. of rows returned--
	exec('select count(*) as TotalDisplayRow from ' +@tmpTbl)
	if @debug=1 exec absp_MessageEx  'Returned third resultset'

	--Fourth Resultset will return the status of BrowserataGen--
	select @BrowserDataStatus
	if @debug=1 exec absp_MessageEx  'Returned fourth resultset'
	if exists(select 1 from SYSOBJECTS where ID = object_id(N'VwSite') and objectproperty(id,N'IsView') = 1)   drop view VwSite
	if exists(select 1 from SYSOBJECTS where ID = object_id(N'VwPol') and objectproperty(id,N'IsView') = 1)   drop view VwPol
	
	select COLUMN_NAME,DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME =  @tmpTbl
	if @debug=1 exec absp_MessageEx  'Returned fifth resultset'
END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
	if exists(select 1 from sys.tables where name=@tmpTbl) exec('drop Table ' + @tmpTbl)
	if exists(select 1 from sys.tables where name=@tmpCntTbl) exec('drop Table ' + @tmpCntTbl)
	if exists(select 1 from SYSOBJECTS where ID = object_id(N'VwSite') and objectproperty(id,N'IsView') = 1)   drop view VwSite
	if exists(select 1 from SYSOBJECTS where ID = object_id(N'VwPol') and objectproperty(id,N'IsView') = 1)   drop view VwPol
END CATCH
end
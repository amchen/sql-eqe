if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GenerateAccountBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateAccountBrowserInfo
end
go

create  procedure absp_GenerateAccountBrowserInfo @exposureKey int	
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    	MSSQL
Purpose: 	The procedure will add all account summary records in the AccountBrowserInfo 
		table  based on the given exposurekey.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @exposureKey  ^^ The exposure key for which the browser information is to be generated.
*/
as
begin
set nocount on;
	
	declare @sql varchar(max);
	declare @minCnt int;
	declare @cnt int;
	declare @chunkSize int;
	declare @BrowserDataGenerated varchar(1);
	 		
	--Return if Browser data has already been generated--
	select @BrowserDataGenerated= IsBrowserDataGenerated  from exposureinfo where ExposureKey =@exposureKey
	if @BrowserDataGenerated='Y' return
	
	set @chunkSize=50000 		
	set @minCnt=0	
	select @minCnt=min(AccountKey) from Account where ExposureKey=@exposureKey;

	create table #TmpTbl_Acc(AccountBrowserInfoRowNum int)
	create index #TmpTbl_Acc_I1 on #TmpTbl_Acc(AccountBrowserInfoRowNum)
		
		 
	--insert in chunks--
	while(1=1)
	begin
		--Insert into AccountBrowser--
		insert into AccountBrowserInfo 
		(ExposureKey,AccountKey,AccountNumber,AccountName,Insured,NumberOfPolicies,NumberOfLocations,Producer,Company,Division ,Branch,UserData1, 
			UserData2,UserData3,PriceOfGas,PriceOfOil,FinancialModelType,IsValid)
		output Inserted.AccountBrowserInfoRowNum
		into #TmpTbl_Acc
		select  ExposureKey,AccountKey,AccountNumber,AccountName,Insured,-99,-99,Producer,Company,Division ,Branch,UserData1,UserData2,UserData3,PriceOfGas,PriceOfOil,FinancialModelType,IsValid
		from Account  where ExposureKey = @exposureKey and AccountKey between @minCnt and @minCnt + (@chunkSize - 1)
		
		--Update number of policies and locations--
		update accountbrowserinfo  
		set NumberOfPolicies= (
			select count(*) from Policy B where accountbrowserinfo.ExposureKey=B.ExposureKey and accountbrowserinfo.AccountKey=B.AccountKey ) ,
		NumberOfLocations= (select count(*) from Structure C where accountbrowserinfo.ExposureKey=C.ExposureKey and accountbrowserinfo.AccountKey=C.AccountKey )
		from accountbrowserinfo
		inner join #TmpTbl_Acc
		on accountbrowserinfo.AccountBrowserInfoRowNum=#TmpTbl_Acc.AccountBrowserInfoRowNum
		
			  
		set @cnt=@@rowCount
	 
		if @cnt=0 or @cnt<@chunkSize break
			
		set @minCnt = @minCnt+@chunkSize
		truncate table #TmpTbl_Acc
 	end
end



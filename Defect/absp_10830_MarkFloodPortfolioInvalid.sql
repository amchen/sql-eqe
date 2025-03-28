if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_10830_MarkFloodPortfolioInvalid') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_10830_MarkFloodPortfolioInvalid;
end
go

create procedure absp_10830_MarkFloodPortfolioInvalid
AS
begin
	set nocount on;

	declare @columnName varchar(120);
	--0010830: Existing Flood Portfolios Need to be Removed or Marked Invalid During DB Migration
	 
	--Get all the Pport and Programs--
	 select ExposureKey, ParentKey as NodeKey,ParentType as NodeType into #T1 from ExposureMap 

	--Get the nodes on which analysis had been performed--
	 select distinct E.ParentKey as NodeKey,E.ParentType as NodeType into #T2 from AnalysisRunInfo A   inner join ExposureMap E on 
		 A.NodeType=E.ParentType and 	Case when E.ParentType=2  and A.PportKey=E.ParentKey then 1
		 when E.ParentType=27 and A.ProgramKey=E.ParentKey then 1  else 0 end=1
		 inner join AvailableReport R on A.AnalysisRunKey=R.AnalysisRunKey
		 
	--Get the portfolios on which analysis has not been performed--
	delete from #T1 from #T1 inner join #T2 on #T1.NodeKey=#T2.NodeKey  and #T1.NodeType=#T2.NodeType

	--Delete the US Flood entries from ExposureModel for the portfolios where analysis has not been performed--
	delete from ExposureModel  from ExposureModel E inner join #T1 T on E.ExposureKey=T.ExposureKey where CountryCode='00' and PerilID='5'
 	
end

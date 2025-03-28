if EXISTS(SELECT 1 FROM sysobjects WHERE id = object_id(N'absp_Util_GetLookupIDsFromMap') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_Util_GetLookupIDsFromMap
end
GO
CREATE procedure absp_Util_GetLookupIDsFromMap @nodeKey int, @nodeType int, @cacheTypeDefID int
As

/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================================
DB Version:    	MSSQL
Purpose:		This utility procedure will return the list of lookup IDs and Names of certain cache type 
                used a node given nodeKey, nodeType and cacheTypeDefID (from CacheTypeDef table)
				For APORT this will return all the lookup IDs and Names used by the child RPORT, PPORT and RAP portfolios.
				 

Returns:		list of treatyTag IDs and Names.


====================================================================================================

</pre>
</font>

##BD_END


##PD   	nodeKey ^^ Node Identifier like, APORT_KEY, PPORT_KEY, RPORT_KEY, PROG_KEY
##PD   	nodeType ^^ Value to identify the node type. Valid values are Accumulation = 1; 
					Primary Portfolio = 2; Reinsurance Portfolio = 3; 
					Reinsurance Account Portfolio = 23... 
*/

begin 

   set nocount on

	-- Create a temp table to store the ExposureKeys.Later we will use absp_Util_GenInList to build the in-list.
	create table #EXP_TBL (ExposureKey int PRIMARY KEY)
	--create table #EXP_TBL2 (ExposureKey int, ID int, Name varchar(75), CacheTypeDefID int)
    
	--CREATE UNIQUE INDEX EXP_TBL2_INDEX  ON #EXP_TBL2 (exposureKey,ID, CacheTypeDefID) 

	if (@nodeType = 1) 
	begin 
		-- for APORT we need to get ExposureKeys related to PPORT, RPORT & RAPort
		insert into #EXP_TBL 
			select ExposureMap.ExposureKey from ExposureMap inner join RportMap on ExposureMap.ParentKey = Rportmap.Child_Key
				inner join Aportmap on Rportmap.Rport_key = Aportmap.Child_key
				and (ParentType = 7 or ParentType = 27) and (Aportmap.Child_Type = 3 or Aportmap.Child_Type = 23)
				and Aportmap.Aport_key = @nodeKey
			union
			select ExposureKey from ExposureMap inner join AportMap on ExposureMap.ParentKey = Aportmap.Child_Key
			   	and ParentType = 2 and Aportmap.child_type = 2
   				and Aportmap.Aport_key = @nodeKey							
	end
	
	else if (@nodeType = 2) 
	begin
		-- for PPORT--
		insert into #EXP_TBL
			select ExposureKey  from ExposureMap where ParentType = 2  and Parentkey = @nodeKey
	end
	
	else if (@nodeType = 3 or @nodeType = 23) 
	begin
		-- for RPORT--
		insert into #EXP_TBL 
			select ExposureKey  from ExposureMap 
			   inner join RportMap on  ExposureMap.ParentKey = Rportmap.Child_Key 
			   and (parentType = 7 or parentType = 27)
			   and Rportmap.Rport_key = @nodeKey		   
	end
	
	else if (@nodeType = 7 Or @nodeType = 27) 
	begin
		-- for Program and Account nodes--
		insert into #EXP_TBL
			select ExposureKey  from ExposureMap where  ParentKey = @nodeKey and (parentType = 7 or parentType = 27)
				   
	end

	else if (@nodeType = 10 Or @nodeType = 30) 
	begin
		-- for case or Treaty--
		insert into #EXP_TBL 
		select ExposureKey  from ExposureMap 
			inner join CaseInfo on CaseInfo.Prog_key = ParentKey
			and (ParentType = 7 or ParentType = 27)
			   and Caseinfo.Case_key = @nodeKey		   					
	end 

	if exists (select 1 from #EXP_TBL)
	begin
--  Only get the first 100 records from ExposureLookupIDMap 
--  insert into #EXP_TBL2 select distinct top 100 ExposureKey, ID, NAME, CacheTypeDefID from ExposureLookupIDMap where CacheTypeDefID=@cacheTypeDefID

		select distinct top 100 ID, NAME from ExposureLookupIDMap where exposureKey 
		in(select exposureKey from #EXP_TBL) and CacheTypeDefID=@cacheTypeDefID order by Name

	end
    else
    begin
		select 0 as ID, 'Unspecified' as NAME
    end
end
if EXISTS(SELECT 1 FROM sysobjects WHERE id = object_id(N'absp_Util_GetExposureKeyList') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_Util_GetExposureKeyList
end
GO
CREATE procedure absp_Util_GetExposureKeyList @ret_inList varchar(max) output, @nodeKey int, @nodeType int
As

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:		This utility procedure will return the list of ExposureKeys for a given nodeKey and nodeType.
				For APORT this will return all the ExposureKeys for the child RPORT, PPORT and RAP portfolios.


Returns:		Nothing.


====================================================================================================

</pre>
</font>

##BD_END

##PD	@ret_inList	^^	An in-list string containing all the ExposureKeys or an Empty String

##PD   	nodeKey ^^ Node Identifier like, APORT_KEY, PPORT_KEY, RPORT_KEY, PROG_KEY
##PD   	nodeType ^^ Value to identify the node type. Valid values are Accumulation = 1;
					Primary Portfolio = 2; Reinsurance Portfolio = 3;
					Reinsurance Account Portfolio = 23, ;
*/

begin

   set nocount on


	-- initialize --
	set @ret_inList = '';

	-- Create a temp table to store the ExposureKeys.Later we will use absp_Util_GenInList to build the in-list.
	create table #EXP_TBL (ExposureKey int);

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

	-- Remove DELETED ExposureKeys
	delete #EXP_TBL where ExposureKey in (select ExposureKey from ExposureInfo where Status='DELETED');

	-- Now call absp_Util_GenInList to build the list.
	if exists (select 1 from #EXP_TBL)
	begin
		exec absp_Util_GenInList @ret_inList OUTPUT, 'select ExposureKey from #EXP_TBL' , 'N';
	end

end

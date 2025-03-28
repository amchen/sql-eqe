if exists(select * from SYSOBJECTS where ID = object_id(N'absp_hasExposure') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_hasExposure
end
 go

create procedure absp_hasExposure @nodeKey int, @nodeType int

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure check whether a node has any Exposures given a node key and a node type

Returns:

=================================================================================
</pre>
</font>
##BD_END

##BPD  @nodeKey ^^ The node key
##BPD  @nodeType ^^ The node type

##RD  @count ^^ The number of exposures

*/
as
begin

   set nocount on
   declare @count int
   
   set @count = 0
   
   if @nodetype = 2 
      select @count = count(1) from exposuremap where ParentKey = @nodeKey and ParentType = @nodeType
   else if @nodetype = 27
	  select @count = count(1) from exposuremap where ParentKey = @nodeKey and ParentType = @nodeType
   else if @nodetype = 23
	  select @count = count(1) from exposureMap inner join rportmap on exposureMap.parentKey = rportmap.child_Key and exposureMap.ParentType = rportmap.child_Type and rportmap.Rport_key = @nodeKey
   else if @nodetype = 30
	 select @count = count(1) from exposureMap inner join proginfo on proginfo.prog_key = exposureMap.parentKey inner join caseInfo on proginfo.prog_key = caseInfo.prog_key and exposureMap.parentType = 27 and caseInfo.case_key = @nodeKey
   
	return @count
end


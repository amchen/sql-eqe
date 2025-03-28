if exists(select 1 from SYSOBJECTS where ID = OBJECT_ID(N'absp_GetChildList') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetChildList;
end
go

create  procedure absp_GetChildList @nodeKey int, @nodeType int

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:	This procedure gets all the child portfolios for the given portfolio
			
Returns:	ResultSet.
=================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey		^^ Key of the portfolio for which we'll get all parent.
##PD  @nodeType		^^ Portfolio type.
*/

as

begin
	set nocount on;

	declare @sql nvarchar (2000);
	declare @msg varchar(4000);
	declare @me varchar(100);
	declare @curs1 cursor;
	declare @childKey int;
	declare @childType int;

	set @me = 'absp_GetChildList';
	set @msg = @me + ' Starting... with ' + str(@nodeKey) + ' and ' + str(@nodeType);
	exec absp_MessageEx @msg;

	begin
		--Create a temporary table to get the list of all parent and child nodes--
		create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT)
		--insert into #NODELIST (NODE_KEY, NODE_TYPE) values (@nodeKey, @nodeType)
	
		-- get all parent nodes
		execute absp_PopulateParentList @nodeKey, @nodeType

		-- get all child nodes
  		execute absp_PopulateChildList @nodeKey, @nodeType

		-- clean up non-Exposure nodes
		delete from #NODELIST where NODE_TYPE not in(2,7,27);

		select NODE_KEY as NodeKey, NODE_TYPE as NodeType from #NODELIST 
	end
end

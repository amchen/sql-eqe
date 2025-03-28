if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateCurrencyUpdate') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_InvalidateCurrencyUpdate
end
go

create  procedure absp_InvalidateCurrencyUpdate  @cupdKey int, @cleanup int = 1
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:  The procedures will invalidate all nodes from CUPDCTRL table.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

 */
as
begin
	set nocount on
	
	declare @nodeKey int
	declare @nodeType int
	
	declare c1 cursor  for 
		select distinct APORT_KEY,1 from CUPDCTRL where APORT_KEY > 0 and CUPD_KEY=@cupdKey
	  	union
	  	select distinct PPORT_KEY,2 from CUPDCTRL where APORT_KEY = 0 and PPORT_KEY > 0 and CUPD_KEY=@cupdKey
	  	union
	  	select distinct RPORT_KEY,23 from CUPDCTRL where  APORT_KEY = 0 and RPORT_KEY > 0 and CUPD_KEY=@cupdKey
	        union	        
	        select distinct PROG_KEY ,27 from CUPDCTRL where  PROG_KEY > 0 and CUPD_KEY=@cupdKey
	        union	        
	        select distinct PROG_KEY ,27 from CUPDCTRL where  CASE_KEY > 0 and CUPD_KEY=@cupdKey
	  
	    --Get the list of all nodes that needs to be invalidated and invalidate each node--
	open c1
	fetch c1 into @nodeKey,@nodeType
	while @@fetch_status=0
	begin
		if @nodeType=1
			exec absp_InvalidateByAportKey @nodeKey, 1, 1;
		else if @nodeType=2
			exec absp_InvalidateByPPortKey @nodeKey, 1, 1;
		else if @nodeType=23
			exec absp_InvalidateByRPortKey @nodeKey, 1, 1;
		else if @nodeType=27
		 	exec absp_InvalidateByProgKey @nodeKey, 1,1;
		else if @nodeType=30
		 	exec absp_InvalidateByTreatyKey @nodeKey, 1,1;

		fetch c1 into @nodeKey,@nodeType
	end;
	close c1;
	deallocate c1;
	 
	if @cleanup > 0 
      		execute absp_CupdCleanup @cupdKey
end;
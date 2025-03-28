if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_QA_CreateCurrencyTree') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_CreateCurrencyTree
end
go

create procedure  absp_QA_CreateCurrencyTree @nodeKey int, @nodeType int =12 , @parentKey int =-1, @parentType  int =-1   
as
begin

	set nocount on

	declare @childKey integer
	declare @childType integer
	declare @msgText varchar(100)
	
	if  OBJECT_ID('tempdb..#TMP_CF_TREE','u') IS NULL
	  create table #TMP_CF_TREE(NODE_KEY int, NODE_TYPE int,  PARENT_KEY int, PARENT_TYPE int)

    set @msgText = 'NodeKey=' + cast(@nodeKey as varchar) +', NodeType=' + cast(@nodeType as varchar) 
	execute absp_MessageEx @msgText


	if @nodeType=0 or @nodeType=12
	begin
	    
		--Insert Folder node
		insert into #TMP_CF_TREE(NODE_KEY,NODE_TYPE, PARENT_KEY, PARENT_TYPE)  values (@nodeKey,@nodeType,0,0)
	    
		--Find child nodes
		declare curs1 cursor for select CHILD_KEY, CHILD_TYPE from FLDRMAP where FOLDER_KEY = @nodeKey 		
		open curs1
		fetch curs1 into @childKey, @childType
		while @@fetch_status=0
		begin
			exec absp_QA_CreateCurrencyTree @childKey,  @childType, @nodeKey, @nodeType 
			fetch curs1 into @childKey, @childType
		end
		close curs1
		deallocate curs1
	end 
	
	else if @nodeType=1
	begin
		--Insert Aport
		insert into #TMP_CF_TREE(NODE_KEY,NODE_TYPE, PARENT_KEY, PARENT_TYPE) values (@nodeKey,@nodeType,@parentKey,@parentType)
		--Find child nodes
		
		declare curs2 cursor for select CHILD_KEY, CHILD_TYPE from APORTMAP where APORT_KEY = @nodeKey  
		open curs2
		fetch curs2 into @childKey, @childType
		while @@fetch_status=0
		begin
			exec absp_QA_CreateCurrencyTree @childKey,  @childType, @nodeKey, 1 
			fetch curs2 into @childKey, @childType
		end
		close curs2
		deallocate curs2
	end 
	
	else if @nodeType=2
	begin
		--Insert Pport
		insert into #TMP_CF_TREE(NODE_KEY,NODE_TYPE, PARENT_KEY, PARENT_TYPE) values (@nodeKey,@nodeType,@parentKey,@parentType)


	end
		
	else if @nodeType=3 or @nodeType=23
	begin
	--Insert Rport
		insert into #TMP_CF_TREE(NODE_KEY,NODE_TYPE, PARENT_KEY, PARENT_TYPE) values (@nodeKey,@nodeType,@parentKey,@parentType)
		--Insert programs  
		insert into #TMP_CF_TREE (NODE_KEY,NODE_TYPE, PARENT_KEY, PARENT_TYPE)
				select distinct CHILD_KEY, CHILD_TYPE, RPORT_KEY, case when CHILD_TYPE=7 then 3 else 23 end as CHILD_TYPE 
				from RPORTMAP inner join  PROGINFO on RPORTMAP.CHILD_KEY = PROGINFO.PROG_KEY
				where RPORT_KEY = @nodeKey and RPORTMAP.CHILD_TYPE in( 7,27)  
				group by CHILD_KEY, CHILD_TYPE, RPORT_KEY,CHILD_TYPE ,LONGNAME, CREATE_DAT
				
					
		--insert Cases
		insert into #TMP_CF_TREE (NODE_KEY,NODE_TYPE, PARENT_KEY, PARENT_TYPE)
				select distinct CASE_KEY,case when RPORTMAP.CHILD_TYPE=7 then 10 else 30 end, RPORTMAP.CHILD_KEY,RPORTMAP.CHILD_TYPE  
				from CASEINFO inner join RPORTMAP 
				on CASEINFO.PROG_KEY=RPORTMAP.CHILD_KEY and RPORTMAP.RPORT_KEY = @nodeKey and  RPORTMAP.CHILD_TYPE in( 7, 27)
				
	end
	
	--Return the resultset for the parent currency node
    if @nodeType=12
		select * from #TMP_CF_TREE
end
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_PopulateParentList') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_PopulateParentList
end

go

create  procedure absp_PopulateParentList @portfolioKey int, @portfolioType int, @extra_Key integer = -1

/* 
##BD_BEGIN  
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose:	   
		This procedure gets all the parents for the given portfolio and populates 
		the data into the given table. 
     
    	    
Returns: Nothing.

=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @portfolioKey		^^ Key of the portfolio for which we'll get all parent.
##PD  @portfolioType	^^ Portfolio type.


*/

as

begin
set nocount on

	declare @sql varchar (2000);
	declare @msg varchar(4000);
	declare @me varchar(100);
	declare @lockId table (LOCK_ID varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS)
	declare @nodeId varchar(1000)
	declare @indx1 int ;
	declare @indx2 int ;
	declare @indx3 int ;
	declare @indx4 int ;
	declare @nodeKey int ;
	declare @nodeType int ;
	declare @parentKey int ;
	declare @parentType int ;
	declare @tmpString char(20);
	declare @len int ;
	declare @curRefkey int;
	
	set @indx1=0;
	set @indx2=0;
	set @indx3=0;
	set @indx4=0;
	set @nodeKey=0;
	set @nodeType=0;
	set @parentKey=0;
	set @parentType=0;
	set @len=0;
	set @nodeId = '';
	
	set @me = 'absp_PopulateParentList';
	set @msg = @me + ' Starting...';
	exec absp_MessageEx @msg;	
	
	-- We'll get lockId for the node and try to get all parent
	
		
	insert into @lockId exec absp_getLockId @portfolioKey, @portfolioType, @extra_Key
	
	select @nodeId = LOCK_ID from @lockId
	
	if (@nodeId = '') 
		return;
	
	
	set @nodeId=@nodeId+'_';
	
   -- get the actual node id
	  select @curRefkey = CF_REF_KEY from CFLDRINFO where DB_NAME=DB_NAME()
	  select @nodeId = REPLACE(@nodeId, '0:' + ltrim(rtrim(str(@curRefkey))) + ':', '')
    -- 
  
	while 1=1
	begin

    set @indx2=@indx1;
    
    select  @indx1 = charindex('_',@nodeId,@indx1+1)
          

    if(@indx1 < 1) begin
      break
    end  
    if(@indx1 >= 1) begin
      set @indx2=@indx2+1
      select @tmpString = substring(@nodeId,@indx2,@indx1-@indx2)
	  
      select @len = len(ltrim(rtrim(@tmpString))) ;
      if(@len > 0) begin
      select  @indx3 = charindex(':',@tmpString,0) 
        
        if(@indx3 = 0) begin
          set @nodeType=0;
          select @nodeKey = cast(@tmpString as int) 
		end
        else begin
          select @nodeType = cast(substring(@tmpString,1,@indx3 -1) as int )  
          
          -- We do not want any policy, case etc.
          if(@nodeType = 8 or @nodeType = 10 or @nodeType =30) begin
          	break
		  end
		  -- if currency node, the node id will contain 'nodeType:curRefKey:nodeKey'
		  -- skip the curRefkey part
		  if(@nodeType = 0) begin
	  		select  @indx4 = charindex(':',@tmpString,@indx3+1)
	  		--select '@indx4=' + str(@indx4)
	  		if @indx4 > 0 set @indx3 = @indx4 
		  		
		  end
	      --select '@indx3=' + str(@indx3)
	      
          --select'@tmpString=' + substring(@tmpString,@indx3+1,len(@tmpString)-@indx3)
          select @nodeKey = cast(substring(@tmpString,@indx3+1,len(@tmpString)-@indx3) as int )
        end  ;
        begin transaction;
			insert into #NODELIST values (@nodeKey,@nodeType,@parentKey,@parentType)
        commit transaction;  
        set @parentKey=@nodeKey
        set @parentType=@nodeType
         
      end  
    end  
    set @len=0
    set @indx2=@indx1
  end 
 
end

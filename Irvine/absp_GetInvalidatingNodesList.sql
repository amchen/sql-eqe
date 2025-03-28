if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_GetInvalidatingNodesList') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetInvalidatingNodesList
end
go
 
create procedure absp_GetInvalidatingNodesList  
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure gets all the invalidating portfolios(APort, PPort, RPort and Program) 
     and returns as a resultset. 
     
    	    
Returns: Resultset.
====================================================================================================
</pre>
</font>
##BD_END 

##RS  NODE_KEY 	^^  Node key of the invalidating portfolio
##RS  NODE_TYPE 	^^  Node type of the invalidating portfolio 
##RS  LONGNAME		^^	Name of the portfolio            
*/
as
begin

set nocount on

declare @nodeKey	integer
declare @nodeType	integer
declare @nodeName	varchar(120)
declare @attrib integer
declare @tableName	varchar(120)
declare @fieldName	varchar(120)
declare @isInvalidating integer
declare @strSQL	nvarchar(1000)
declare @cursInfoTbl cursor
declare @cnt integer
declare @bitValue integer
declare @invalidatingValue integer



create table #TMPINVALIDATINGNODEINFO (NODE_KEY INT, NODE_TYPE INT, LONGNAME varchar(120)  COLLATE SQL_Latin1_General_CP1_CI_AS)

select @invalidatingValue = ATTRIBVAL from ATTRDEF where ATTRIBNAME = 'INVALIDATING'
 
 declare cursTblNames cursor for select TABLENAME from dbo.absp_Util_GetTableList('Invalidate.Info')
 open cursTblNames
	fetch cursTblNames into @tableName
	while @@fetch_status=0
	begin
 
		select @fieldName = FIELDNAME from DICTCOL where COLSUBTYPE = 'K' and TABLENAME = @tableName
		
		if(@tableName = 'RPRTINFO' or @tableName = 'PROGINFO')
		begin
			if(@tableName = 'RPRTINFO')
				set @nodeType = 3
			else if(@tableName = 'PROGINFO')
				set @nodeType = 7
				
			set @strSQL = 'select ' + @fieldName + ', case when MT_FLAG = ''Y'' then ' + str(@nodeType + 20) + ' else ' + str(@nodeType) + ' end, LONGNAME, ATTRIB from ' + @tableName	
		end
		else
		begin
			if(@tableName = 'APRTINFO')
				set @nodeType = 1
			else if(@tableName = 'PPRTINFO')
				set @nodeType = 2
			
			set @strSQL = 'select ' + @fieldName + ', ' + str(@nodeType) + ', LONGNAME, ATTRIB from ' + @tableName
		end
		set @strSQL = 'set @cursInfoTbl = cursor static for ' + @strSQL  + ' ; open @cursInfoTbl'
		exec sp_executesql @strSQL, N'@cursInfoTbl cursor OUTPUT', @cursInfoTbl OUTPUT
		
			fetch @cursInfoTbl into @nodeKey, @nodeType, @nodeName, @attrib
			while @@fetch_status=0
			begin
				set @cnt = 0
				set @bitValue = 0
				set @isInvalidating = 0
				while(@attrib > 0)
				begin
					set @bitValue =  @attrib % 2
					set @attrib = @attrib/2
					set @isInvalidating = power(2, @cnt) * @bitValue;
					if(@isInvalidating >= @invalidatingValue)
						break
					set @cnt = @cnt + 1
				end
				
				if(@isInvalidating = @invalidatingValue)
					insert into #TMPINVALIDATINGNODEINFO values (@nodeKey, @nodeType, @nodeName)
									
			fetch @cursInfoTbl into @nodeKey, @nodeType, @nodeName, @attrib
			end
		 close @cursInfoTbl
		 deallocate @cursInfoTbl
		 
	fetch cursTblNames into @tableName
	end
 close cursTblNames
 deallocate cursTblNames
     
 select * from #TMPINVALIDATINGNODEINFO   
 
end
 
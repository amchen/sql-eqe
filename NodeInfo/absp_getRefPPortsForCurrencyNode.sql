if exists(select * from SYSOBJECTS where id = object_id(N'absp_getRefPPortsForCurrencyNode') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getRefPPortsForCurrencyNode
end
go
create procedure absp_getRefPPortsForCurrencyNode  
    @curr_key     int,
    @port_key     int

-- This procedure will return a list of all the pport_keys and longNames those are underneath the currency node key
-- that is passed as an argument to the procedure.  

/*
##BD_BEGIN absp_getRefPPortsForCurrencyNode ^^
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:

    This procedure will return a list of all pport node keys and node names under a currency node 
    excluding the pport node key passed as an input parameter.
    
Returns:         A list of  @portKey and @portName  
                

====================================================================================================
</pre>
</font>
##BD_END

##PD curr_key ^^  The key of the currency node for which the child pports need to be identified. 
##PD port_key ^^  The pport node key that is excluded from the list of returned pports. 

*/
as
begin

   set nocount on
   declare @sql varchar(max)
   
--message 'absp_getRefPPortsForCurrencyNode ', ' curr_key = ', curr_key, ', port_key = ', port_key;

-- create temporary table
 create table #PPRT_REF_TMP(PPORT_KEY integer);
			     

 create index #PPRT_REF_TMP_I1 on #PPRT_REF_TMP (PPORT_KEY);

--return @portKey and @portname;
 insert into #PPRT_REF_TMP(PPORT_KEY) select CHILD_KEY from CURRMAP where FOLDER_key = @curr_key 
 and child_key <> @port_key and child_type = 2 order by child_key;
 
 select PPRTINFO.PPORT_KEY, PPRTINFO.LONGNAME from PPRTINFO JOIN #PPRT_REF_TMP
	            ON PPRTINFO.PPORT_KEY = #PPRT_REF_TMP.PPORT_KEY  AND PPRTINFO.STATUS = 'ACTIVE' ORDER BY PPRTINFO.LONGNAME;

end
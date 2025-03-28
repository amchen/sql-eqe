if exists(select * from SYSOBJECTS where id = object_id(N'absp_getRefRPortsForCurrencyNode') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getRefRPortsForCurrencyNode
end
go
create procedure absp_getRefRPortsForCurrencyNode  
    @curr_key     int,
    @port_key     int

-- This procedure will return a list of all the rport_keys and longNames those are underneath the currency node key
-- that is passed as an argument to the procedure.  

/*
##BD_BEGIN absp_getRefPPortsForCurrencyNode ^^
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:

    This procedure will return a list of all rport node keys and node names under a currency node 
    excluding the pport node key passed as an input parameter.
    
Returns:         A list of  @rportKey and @rportName  
                

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
   
--message 'absp_getRefRPortsForCurrencyNode ', ' curr_key = ', curr_key, ', port_key = ', port_key;

-- create temporary table
 create table #RPRT_REF_TMP(RPORT_KEY integer);
			     

 create index #RPRT_REF_TMP on #RPRT_REF_TMP (RPORT_KEY);

--return @portKey and @portname;
 insert into #RPRT_REF_TMP(RPORT_KEY) select CHILD_KEY from CURRMAP where FOLDER_key = @curr_key 
 and child_key <> @port_key and child_type =3 order by child_key;
 
 select RPRTINFO.RPORT_KEY, RPRTINFO.LONGNAME from RPRTINFO JOIN #RPRT_REF_TMP
	            ON RPRTINFO.RPORT_KEY = #RPRT_REF_TMP.RPORT_KEY  AND RPRTINFO.STATUS = 'ACTIVE' ORDER BY RPRTINFO.LONGNAME;

end
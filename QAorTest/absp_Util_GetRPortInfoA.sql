if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_GetRPortInfoA') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_GetRPortInfoA
end
 go
create procedure absp_Util_GetRPortInfoA 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    ASA
Purpose:

    This procedure provides all the basic information such as names/keys/etc. for all existing 
    reinsurance or reinsurance account portfolios in the database

  	    
Returns:	Nothing
                   
====================================================================================================
</pre>
</font>
##BD_END
*/
as
begin
	select rprtinfo.rport_key,
		rprtinfo.longname as rportname,
	  	'R' as reintype,
	  	prog_key,
    		proginfo.longname as progname,
    		ExposureMap.ExposureKey
	from 
		rprtinfo,rportmap,proginfo,ExposureMap
	where
		rprtinfo.rport_key = rportmap.rport_key and
		rportmap.child_key = proginfo.prog_key and 
		rportmap.child_type = 7 and ExposureMap.ParentType = rportmap.child_type and 
		ExposureMap.ParentKey = PROGINFO.PROG_KEY
union
	select rprtinfo.rport_key,
		rprtinfo.longname as rportname,
	  	'RA' as reintype,
	  	prog_key,
    		proginfo.longname as progname,
    		ExposureMap.ExposureKey
	from 
		rprtinfo,rportmap,proginfo,ExposureMap
	where
		rprtinfo.rport_key = rportmap.rport_key and
		rportmap.child_key = proginfo.prog_key and 
		rportmap.child_type = 27 and ExposureMap.ParentType = rportmap.child_type and 
		ExposureMap.ParentKey = PROGINFO.PROG_KEY
order by 1 desc,4 asc
end
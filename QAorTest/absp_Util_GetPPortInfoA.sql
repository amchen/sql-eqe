if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_GetPPortInfoA') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_GetPPortInfoA
end
go
create procedure absp_Util_GetPPortInfoA
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    ASA
Purpose:

    This procedure provides all the basic information such as names/keys/etc. for all existing 
    primary portfolios in the database

  	    
Returns:	Nothing
                   
====================================================================================================
</pre>
</font>
##BD_END
*/
as
begin
	select pprtinfo.pport_key,
		pprtinfo.longname as pportname,
		ExposureMap.ExposureKey
	from 
		pprtinfo,ExposureMap
	where
		ExposureMap.ParentType = 2 and PPRTINFO.PPORT_KEY = ExposureMap.ParentKey
	order by
		pprtinfo.pport_key desc

end
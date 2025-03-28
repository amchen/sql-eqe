if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetDLLBuildNumber') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetDLLBuildNumber
end

go
create  procedure --------------------------------------------------------------
absp_Util_GetDLLBuildNumber @ret_Build char(255) output 
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure calls an external function which in turn returns a string containing the current
version of the WCE Application, EQE Application and the first build.

Returns:       	Nothing.
====================================================================================================
</pre>
</font>
##BD_END 

##PD @ret_Build ^^ An OUTPUT parameter where the current version of WCE Application, EQE Application and EQESYB.DLL is returned.
*/

    -- exception handling for old version of the DLL
as
begin

   set nocount on
   
   declare @theBuildNumber char(255)

   --    return @ret_Build;
begin try
      set @theBuildNumber = dbo.absxp_GetDLLBuildNumber()
      print 'absp_Util_GetDLLBuildNumber: Current build = '+@theBuildNumber
      set @ret_Build = rtrim(ltrim(@theBuildNumber))
end try
begin catch
      print 'absp_Util_GetDLLBuildNumber: Old version of Eqesyb.dll!'
      set @ret_Build = '3.6.00/5.8.00 (B1083c75)'

end catch
end



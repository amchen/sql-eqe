if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getExchRportFolderName') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_getExchRportFolderName
end

go

create procedure absp_getExchRportFolderName (@ret_NodeName char(120) output, @currNodeKey int)
--returns varchar(max)
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

    This procedure will append the given node key to a string '_myPportToRportConversions_' 
    and return it back in an Output parameter.

Returns:       Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_NodeName ^^  Returns a string containing the given nodeKey appended to '_myPportToRportConversions_'.
##PD  @currNodeKey ^^  Takes the current node key.



*/
   as
begin
   -- defect SDG__00012266 and SDG__00012179: append the currency node key

   set nocount on
   
   set @ret_NodeName  = '_myPportToRportConversions_'+rtrim(ltrim(str(@currNodeKey)))
   
end





if exists(select * from sysobjects where id = object_id(N'absp_TreeviewRPortfolioRename') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_TreeviewRPortfolioRename
end

go
create procedure absp_TreeviewRPortfolioRename @rportKey int ,@newName char(120) 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:       This procedure renames a reinsurance portfolio to given newName for given rportKey 
    	       passed as parameters.

Returns:     It returns nothing. It just uses the UPDATE statement to rename a portfolio.    

====================================================================================================
</pre>
</font>
##BD_END

##PD  rportKey ^^  The key for the reinsurance portfolio that is to be renamed.
##PD  newName ^^  The new name of the reinsurance portfolio

*/

as
begin
   update RPRTINFO set LONGNAME = @newName where RPORT_KEY = @rportKey
end




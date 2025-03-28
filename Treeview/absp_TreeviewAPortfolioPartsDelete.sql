if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_treeviewAportfolioPartsDelete') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_treeviewAportfolioPartsDelete
end
 go

create procedure absp_treeviewAportfolioPartsDelete @aportKey int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes all the aport parts for a given aport node key.
Aport parts include the following:-
1) Retro Treaty Exclusions
2) Retro Treaty Industry Loss Triggers
3) Retro Treaty Layer Data
4) Retro Treaty Map
5) Retro Participation for Each Reinsurer for Each Layer
6) Retro Treaty Information



Returns:       It returns nothing. It uses the DELETE statement to remove all the aport parts from the database.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @aportKey ^^  The key of the aport node for which the parts are to be removed. 


*/
as
begin
         set nocount on
	  -- deletes all the child parts of an aport
	  -- for each retro associated with that aport_key
	  -- how about the inuring layers
	     declare @curs2_RK int
	     declare @curs2 cursor
	
	  -- delete the parts
	  set @curs2 = cursor fast_forward for 
	          select RTRO_KEY  from RTROINFO where PARENT_KEY = @aportKey and PARENT_TYP = 1
	  open @curs2
	  fetch next from @curs2 into @curs2_RK
	  while @@fetch_status = 0
	  begin
		  delete from RTROEXCL where RTRO_KEY = @curs2_RK
		  --delete from RTROTRIG where RTRO_KEY = @curs2_RK
		  delete from RTROLAYR where RTRO_KEY = @curs2_RK
		  delete from RTROMAP where RTRO_KEY = @curs2_RK
		  delete from RTROPART where RTRO_KEY = @curs2_RK
		  fetch next from @curs2 into @curs2_RK
	   end
	   close @curs2
	   deallocate @curs2
	  -- now the rtroinfo
	   delete from RTROINFO where PARENT_KEY = @aportKey and PARENT_TYP = 1
end






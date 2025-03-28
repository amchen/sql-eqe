if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdDriver') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdDriver;
end
go

create procedure absp_CupdDriver
	@nodeKey int ,
	@nodeType int ,
	@parentKey int ,
	@parentType int ,
	@policyKey int = 0 ,
	@siteKey int = 0 ,
	@oldCurrsKey int ,
	@newCurrsKey int ,
	@doItFlag int = 1 ,
	@debugFlag int = 0 ,
	@sourceDB varchar(130)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure performs a currency conversion from an old currency schema to a
			new one for a given node and returns the currency update key.
Returns:	The currency update key.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey ^^  The key of the node for which the currency conversion is to be done.
##PD  @nodeType ^^  The type of node for which the currency conversion is to be done.
##PD  @policyKey ^^  The policy key for which the currency conversion is to be done.
##PD  @siteKey ^^  The site key for which the currency conversion is to be done.
##PD  @oldCurrsKey ^^  The key of the existing currency schema.
##PD  @newCurrsKey ^^  The key of the currency schema to which the conversion will take place.
##PD  @doItFlag ^^  Unused parameter in the proc and the called procs.
##PD  @cleanupFlag ^^  A flag to indicate if cleanup is required after conversion.
##PD  @debugFlag ^^  The debug flag

##RD  @cupdKey^^ The currency update key.
*/
as

begin

   set nocount on;

   declare @idbName varchar(130);
   declare @sql nvarchar(2000);

   if (@sourceDB = '')
      set @sourceDB = DB_NAME();

   --Enclose within square brackets--
   execute absp_getDBName @sourceDB out, @sourceDB;

   if exists (select 1 from RQEVersion where DbType='EDB')
   begin
      execute absp_getDBName @idbName out, @sourceDB, 1;
   end
   else
   begin
      set @idbName = @sourceDB;
   end

 /*
  This will get you set up to do a currency conversion
  of a given node to a new currency schema from an old currency schema
  */
  --SDG__00015444 -remove unused cleanupFlag
  -- standard declares
   declare @me varchar(255);
   declare @debug int;
   declare @doIt int;
   declare @cupdKey int;
   declare @rtroKey int;
   declare @err int;
   declare @msgTxt01 varchar(255);

   set @me = 'absp_CupdDriver: '; -- set to my name (name_of_proc plus ': '
   set @doIt = @doItFlag; -- initialize
   set @debug = @debugFlag; -- initialize

   if @debug > 0
   begin
	set @msgTxt01 = @me+'starting';
	execute absp_messageEx @msgTxt01;
   end

   exec @cupdKey = absp_CupdPrep @nodeKey,@nodeType,@policyKey,@siteKey,@oldCurrsKey,@newCurrsKey,@doIt,@debug,@sourceDB;

  -- initialize keys
   set @rtroKey = 0;

   if @cupdKey > 0
   begin
		-- 0008324: When you change the currency schema exposure tables are not invalidated
		set @sql = N'USE ' + @idbName + '; truncate table ExposureValue;';
		exec (@sql);

	  -- save values/records for retrieving when mapping tables are reinstated
	  if @parentType = 1
	  begin
	  -- node is under an APort
		 if @nodeType = 2 or @nodeType = 3 or @nodeType = 23
		 begin
			-- save the retroKey
			select  @rtroKey = RTRO_KEY  from RTROMAP where CHILD_APLY = @nodeKey and
			child_type = @nodeType
			select  @err = @@ERROR
		 end
	  end
	--SDG__00015444 - if node is currency node (type=12), also skip map removal and reinserting
	-- only remove Map Entry from the parent if i am not a policy/site currency node
	  if @nodeType <> 8 and @nodeType <> 9 and @nodeType <> 12
	  begin
		 set @msgTxt01 = @me+'before calling removeMapEntry'
		 execute absp_messageEx @msgTxt01
		 execute absp_RemoveMapEntry @nodeKey,@nodeType,@parentKey,@parentType,@policyKey,@siteKey
		 set @msgTxt01 = @me+'after calling removeMapEntry'
		 execute absp_messageEx @msgTxt01
	  end
	  execute absp_CupdUpdate @cupdKey,@doIt,@debug
	-- reinstate entries in the parent map
	  if @nodeType <> 8 and @nodeType <> 9 and @nodeType <> 12
	  begin
		 set @msgTxt01 = @me+'before calling absp_AddMapEntry'
		 execute absp_messageEx @msgTxt01
		 execute absp_AddMapEntry @nodeKey,@nodeType,@parentKey,@parentType,@policyKey,@siteKey,@rtroKey
		 set @msgTxt01 = @me+'after calling absp_AddMapEntry'
		 execute absp_messageEx @msgTxt01
	  end
   end
   if @debug > 0
   begin
	  set @msgTxt01 = @me+'completed for @cupdKey = '+rtrim(ltrim(str(@cupdKey)))
	  execute absp_messageEx @msgTxt01
   end

  -- return the cupdKey
   return @cupdKey;
end

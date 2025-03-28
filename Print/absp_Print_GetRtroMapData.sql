if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Print_GetRtroMapData') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Print_GetRtroMapData;
end
go

create procedure absp_Print_GetRtroMapData @node_key int, @debugFlag int = 0
/*
====================================================================================================
Purpose:	This procedure returns a single result set containing name of all portfolios (rport & pport)
			governed by the Retro treaty specified under the specified accumulation portfolio.

Returns:	Single result set containing a list of retro keys and name of portfolios (rport & pport) under the given aport

			RTRO_KEY ^^ The retro treaty key
			PORTNAMELIST ^^ A list of portfolio names to which the treaties belonging to the given node are applied.
====================================================================================================

@node_key 	^^ Key of the accumulation portfolio.
@debugFlag	^^ Debug flag (debugged if value > 0)
*/
as

begin

   set nocount on

  -- standard declares
	declare @me varchar(255)
	declare @debug int
	declare @msg varchar(255)
	declare @sql varchar(255)
	declare @trtyKeyList varchar(255)
	declare @rtroKey int
	declare @flg int
	declare @rKey int
	declare @rKey_fld int
	declare @lName varchar(120)
	declare @NameList varchar(1000)
	declare @comma varchar(3)
	declare @sql1 nvarchar(255)

  -- declare all temporary tables here
  -- initialize standard items
   set @me = 'absp_Print_GetRtroMapData: ' -- set to my name Procedure Name
   set @debug = @debugFlag -- initialize
   set @msg = @me+'starting'
   set @sql = ''
   if @debug > 0
   begin
	  execute absp_messageEx @msg
   end
   set @sql = 'select RTRO_KEY from RTROINFO where parent_key = '+str(@node_key)
   execute absp_Util_GenInList @trtyKeyList output, @sql
  -- Get primary child information (CHILD_TYPE = 2)

   ---- Create the temporary table--------------------------
   create table #PRINT_RTROMAP
	(
		rtro_key int,
		longname varchar(120)
	 COLLATE SQL_Latin1_General_CP1_CI_AS);


   set @sql = ' insert into #PRINT_RTROMAP select distinct rtro_key, longname from rtromap inner join pprtinfo on pport_key = child_aply where child_type = 2 and rtro_key '+@trtyKeyList

   if @debug > 0
   begin
	  execute absp_messageEx @sql
   end
   execute(@sql)
  -- Get reinsurance child information (CHILD_TYPE = 3)
   set @sql = ' insert into #PRINT_RTROMAP select distinct rtro_key, longname from rtromap inner join rprtinfo on rport_key = child_aply where (child_type = 3 or child_type = 23) and rtro_key '+@trtyKeyList
   if @debug > 0
   begin
	  execute absp_messageEx @sql
   end
   execute(@sql)
  -- Get portfolios that applies to all layers (applies to PR or SS treaty types).
   set @sql = ' insert into #PRINT_RTROMAP select distinct rtro_key, ''All Portfolios'' from rtromap t1 where child_aply=0 and child_type= 0 and rtro_key '+@trtyKeyList
   if @debug > 0
   begin
	  execute absp_messageEx @sql
   end
   execute(@sql)

   create table #tmpPRINT_RTROMAP
   (
	RTRO_KEY int,
	PORTNAMELIST varchar(120) --Change column_name to sycnronize with ASA
    COLLATE SQL_Latin1_General_CP1_CI_AS);


   declare curs1 cursor local for select rtro_key,longname from #PRINT_RTROMAP order by rtro_key asc;
   set @rKey = 0
   set @NameList = ''
   set @comma = ''

   open curs1
   fetch next from curs1 into @rtroKey, @lName

   while @@fetch_status = 0
   begin
	set @rKey = @rtroKey
	set @rKey_fld = @rtroKey

	while @rKey = @rtroKey
	begin
		if @@fetch_status <> 0
		begin
			set @rKey = 0
		end
		else
		begin
			set @NameList = ltrim(rtrim(@NameList)) + @comma + ltrim(rtrim(@lName))
			set @NameList = ltrim(rtrim(@NameList))
			set @comma = ', '
			fetch next from curs1 into @rtroKey, @lName
		end
        end
        set @sql1 = ' insert into #tmpPRINT_RTROMAP select @rKey_fld,@NameList'
        execute sp_executesql @sql1,N'@rKey_fld int output, @NameList varchar(1000) output',@rKey_fld output, @NameList output
        set @comma = ''
        set @NameList = ''
   end
   select * from #tmpPRINT_RTROMAP

   close curs1
   deallocate curs1
   if @debug > 0
   begin
      set @msg = @me+'complete'
      execute absp_messageEx @msg
   end
end

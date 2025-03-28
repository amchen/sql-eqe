if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MakeMultiCountryPrograms') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeMultiCountryPrograms
end
go

create procedure absp_MakeMultiCountryPrograms  @keepExisting int = 0, @cleanupOnly int = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:

    This procedure cleans up the treeview and adds new nodes - folders, aports, rports, programs,cases
    based on the keepExisting and cleanupOnly flags.

    	    
Returns:       It returns nothing.
                   
====================================================================================================
</pre>
</font>
##BD_END

##PD  keepExisting ^^  A flag to indicate if the nodes of the treeview are to be kept intact before the new nodes are added.
##PD  cleanupOnly ^^  A flag to indicate if the treeview is to be cleaned up only and new nodes are not added to it.

*/
as
begin

	declare @parentNodeKey int
	declare @parentNodeType int
	
	declare @newFKey1 int

	declare @newApKey1 int
	declare @newApKey2 int
	declare @newApKey3 int
	declare @newApKey4 int
	declare @newApKey5 int
	declare @newApKey6 int

	declare @newRpKey1 int
	declare @newRpKey2 int
	declare @newRpKey3 int
	declare @newRpKey4 int
	declare @newRpKey5 int

	declare @newPgKey1 int
	declare @newPgKey2 int
	declare @newPgKey3 int
	declare @newPgKey4 int
	declare @newPgKey5 int

	declare @newPgKey1a int
	declare @newPgKey2a int
	declare @newPgKey3a int
	declare @newPgKey4a int
	declare @newPgKey5a int

	declare @newFlKey1 int
	declare @newFlKey2 int
	declare @newFlKey3 int
	declare @newFlKey4 int
	declare @newFlKey5 int

	declare @newBcKey1 int

	declare @newCsLayerKey1 int

	declare @cnt int
	declare @max int
   
    declare @rportKey int
    declare @pportKey int
    declare @aportKey int
    declare @fldrKey int
    declare @progKey int
    declare @createDate char(25)
    declare @longName varchar(120)
    

    -- delete any leftovers from prior runs unless told not to
	if @keepExisting = 0 or @cleanupOnly = 1 
    begin
		-- delete rports
		declare curs_rprtinfo cursor fast_forward for
			select RPORT_KEY as RPK from RPRTINFO where LONGNAME like 'psb_rp%'
		open curs_rprtinfo
        fetch next from curs_rprtinfo into @rportKey
        while @@fetch_status = 0
        begin
			exec absp_FindNodeParent @parentNodeKey output, @parentNodeType output, @rportKey, 3
            exec absp_TreeviewRPortfolioDelete @parentNodeKey, @parentNodeType, @rportKey, -2 
            fetch next from curs_rprtinfo into @rportKey
		end 	
        close curs_rprtinfo
        deallocate curs_rprtinfo
        
		-- delete pports
		declare curs_pprtinfo cursor fast_forward for
			select PPORT_KEY as PPK from PPRTINFO where LONGNAME like 'psb_pp%'
		open curs_pprtinfo
        fetch next from curs_pprtinfo into @pportKey
        while @@fetch_status = 0
        begin
			exec absp_FindNodeParent  @parentNodeKey output, @parentNodeType output, @pportKey, 2
			exec absp_TreeviewPPortfolioDelete @parentNodeKey, @parentNodeType, @pportKey, -2 
		    fetch next from curs_pprtinfo into @pportKey
		end 	
        close curs_pprtinfo
        deallocate curs_pprtinfo	
        
		-- delete aports
		declare curs_aprtinfo cursor fast_forward for
			select APORT_KEY as APK from APRTINFO where LONGNAME like 'psb_ap%'
		open curs_aprtinfo
        fetch next from curs_aprtinfo into @aportKey
        while @@fetch_status = 0
        begin
			exec absp_FindNodeParent @parentNodeKey output, @parentNodeType output, @aportKey, 1 
			exec absp_TreeviewAPortfolioDelete @parentNodeKey, @parentNodeType, @aportKey, -2
            fetch next from curs_aprtinfo into @aportKey
		end 	
        close curs_aprtinfo
        deallocate curs_aprtinfo

		-- delete folders
		declare curs_fldrinfo cursor fast_forward for
			select FOLDER_KEY as FK from FLDRINFO where LONGNAME like 'psb_tf%'
		open curs_fldrinfo
        fetch next from curs_fldrinfo into @fldrKey
        while @@fetch_status = 0
        begin
			exec absp_FindNodeParent @parentNodeKey output, @parentNodeType output, @fldrKey, 0 
			exec absp_TreeviewFolderDelete @parentNodeKey, @fldrKey , -2
            fetch next from curs_fldrinfo into @fldrKey
		end 	
        close curs_fldrinfo
        deallocate curs_fldrinfo
	end 	

	if @cleanupOnly = 1 
		return

	-- make new folder
    exec absp_Util_GetDateString @createDate output, 'yyyymmddhhnnss'
    set @longName = 'psb_tf_' + ltrim(rtrim(@createDate)) + '-1'
	exec @newFKey1 = absp_TreeviewAddChildNode 1, 0, 0, @longName, 1, 1, 0

	-- make new aports
    set @longName =  'psb_ap_' + ltrim(rtrim(@createDate)) + '-1'
	exec @newApKey1 = absp_TreeviewAddChildNode @newFKey1, 0, 1, @longName, 1, 1, 0
	set @longName =  'psb_ap_' + ltrim(rtrim(@createDate)) + '-2'
    exec @newApKey2 = absp_TreeviewAddChildNode @newFKey1, 0, 1, @longName, 1, 1, 0
	set @longName =  'psb_ap_' + ltrim(rtrim(@createDate)) + '-3'
    exec @newApKey3 = absp_TreeviewAddChildNode @newFKey1, 0, 1, @longName, 1, 1, 0
	set @longName =  'psb_ap_' + ltrim(rtrim(@createDate)) + '-4'
    exec @newApKey4 = absp_TreeviewAddChildNode @newFKey1, 0, 1, @longName, 1, 1, 0
	set @longName =  'psb_ap_' + ltrim(rtrim(@createDate)) + '-5'
    exec @newApKey5 = absp_TreeviewAddChildNode @newFKey1, 0, 1, @longName, 1, 1, 0
	set @longName =  'psb_ap_' + ltrim(rtrim(@createDate)) + '-6'
    exec @newApKey6 = absp_TreeviewAddChildNode @newFKey1, 0, 1, @longName, 1, 1, 0

	-- make new rports
    set @longName = 'psb_rp_' + ltrim(rtrim(@createDate)) + '-1'
	exec @newRpKey1 = absp_TreeviewAddChildNode  @newApKey4, 1, 3, @longName, 1, 1, 0
	set @longName = 'psb_rp_' + ltrim(rtrim(@createDate)) + '-2'
    exec @newRpKey2 = absp_TreeviewAddChildNode  @newApKey1, 1, 3, @longName, 1, 1, 0
	set @longName = 'psb_rp_' + ltrim(rtrim(@createDate)) + '-3'
    exec @newRpKey3 = absp_TreeviewAddChildNode  @newApKey5, 1, 3, @longName, 1, 1, 0
	set @longName = 'psb_rp_' + ltrim(rtrim(@createDate)) + '-4'
    exec @newRpKey4 = absp_TreeviewAddChildNode  @newApKey3, 1, 3, @longName, 1, 1, 0
	set @longName = 'psb_rp_' + ltrim(rtrim(@createDate)) + '-5'
    exec @newRpKey5 = absp_TreeviewAddChildNode  @newApKey2, 1, 3, @longName, 1, 1, 0

	-- make new programs
    set @longName = 'psb_pg_' + ltrim(rtrim(@createDate)) + '-1'
	exec @newPgKey1 = absp_TreeviewAddChildNode  @newRpKey3, 3, 7, @longName, 1, 1, 0
	set @longName = 'psb_pg_' + ltrim(rtrim(@createDate)) + '-2'
    exec @newPgKey2 = absp_TreeviewAddChildNode  @newRpKey1, 3, 7, @longName, 1, 1, 0
	set @longName = 'psb_pg_' + ltrim(rtrim(@createDate)) + '-3'
    exec @newPgKey3 = absp_TreeviewAddChildNode  @newRpKey2, 3, 7, @longName, 1, 1, 0
	set @longName = 'psb_pg_' + ltrim(rtrim(@createDate)) + '-4'
    exec @newPgKey4 = absp_TreeviewAddChildNode  @newRpKey5, 3, 7, @longName, 1, 1, 0
	set @longName = 'psb_pg_' + ltrim(rtrim(@createDate)) + '-5'
    exec @newPgKey5 = absp_TreeviewAddChildNode  @newRpKey4, 3, 7, @longName, 1, 1, 0
	
    set @longName = 'psb_pg_' + ltrim(rtrim(@createDate)) + '-1a'
	exec @newPgKey1a = absp_TreeviewAddChildNode  @newRpKey3, 3, 7, @longName, 1, 1, 0
	set @longName = 'psb_pg_' + ltrim(rtrim(@createDate)) + '-2a'
    exec @newPgKey2a = absp_TreeviewAddChildNode  @newRpKey1, 3, 7, @longName, 1, 1, 0
	set @longName = 'psb_pg_' + ltrim(rtrim(@createDate)) + '-3a'
    exec @newPgKey3a = absp_TreeviewAddChildNode  @newRpKey2, 3, 7, @longName, 1, 1, 0
	set @longName = 'psb_pg_' + ltrim(rtrim(@createDate)) + '-4a'
    exec @newPgKey4a = absp_TreeviewAddChildNode  @newRpKey5, 3, 7, @longName, 1, 1, 0
	set @longName = 'psb_pg_' + ltrim(rtrim(@createDate)) + '-5a'
    exec @newPgKey5a = absp_TreeviewAddChildNode  @newRpKey4, 3, 7, @longName, 1, 1, 0

	-- do paste linking all five rports into one aport
	insert into APORTMAP values (@newApKey6, @newRpKey1, 3)
	insert into APORTMAP values (@newApKey6, @newRpKey2, 3)
	insert into APORTMAP values (@newApKey6, @newRpKey3, 3)
	insert into APORTMAP values (@newApKey6, @newRpKey4, 3)
	insert into APORTMAP values (@newApKey6, @newRpKey5, 3)

	declare curs_proginfo cursor fast_forward for
		select PROG_KEY as PK from PROGINFO where PROG_KEY between @newPgKey1 and @newPgKey5a
	open curs_proginfo
        fetch next from curs_proginfo into @progKey
        while @@fetch_status = 0
        begin
		-- i put under each rport two progs: first is 2 files each (bad), next is 1 file each (good)
		set @cnt = 0

		-- how about a case?
        	set @longName = 'psb_bc' + ltrim(rtrim(@createDate)) + '-1'
		exec @newBcKey1 = absp_TreeviewAddChildNode @progKey, 7, 10, @longName, 1, 1, 0

		-- add a couple of layers
		insert into CASELAYR 
			(CASE_KEY, LNUMBER, OCC_LIMIT, OCC_ATTACH, PCT_ASSUME, PCT_PLACE, CALCR_ID, CLLIM_VAL, CLLIM_CC, CLATT_VAL, CLATT_CC)
			values
			(@newBcKey1, 1, 100000, 0, 100, 100, 1, 100, 'USD_K', 0, 'USD_K')

		set @newCsLayerKey1 = @@identity

		-- a reinstatement for that layer_key (in @ident)
		insert into CASEREIN (CASE_KEY, CSLAYR_KEY, REIN_NUM, PCT_OFPREM)
			values (@newBcKey1, @newCsLayerKey1, 1, 100)

		insert into CASELAYR 
			(CASE_KEY, LNUMBER, OCC_LIMIT, OCC_ATTACH, PCT_ASSUME, PCT_PLACE, CALCR_ID, CLLIM_VAL, CLLIM_CC, CLATT_VAL, CLATT_CC)
			values
			(@newBcKey1, 2, 250000, 100000, 100, 100, 1, 250, 'USD_K', 100, 'USD_K')

		set @newCsLayerKey1 = @@identity

		-- a couple of reinstatement2 for that layer_key (in @ident)
		insert into CASEREIN (CASE_KEY, CSLAYR_KEY, REIN_NUM, PCT_OFPREM)
		values (@newBcKey1, @newCsLayerKey1, 1, 77)
       
		insert into CASEREIN (CASE_KEY, CSLAYR_KEY, REIN_NUM, PCT_OFPREM)
		values (@newBcKey1, @newCsLayerKey1, 2, 23)

	
		-- point to base case
		-- while at it, fix up expiration date et al
        	print 'here '
        	update PROGINFO set
			INCEPT_DAT =  left(CREATE_DAT,8),
			EXPIRE_DAT = left ( CREATE_DAT, 3) + '8' + left(substring(CREATE_DAT,5,len(CREATE_DAT) -5),4),
			GROUP_NAM = 'None',
			BROKER_NAM = 'None',
			BCASE_KEY = @newBcKey1
		where PROG_KEY = @progKey
		fetch next from curs_proginfo into @progKey
	end 
    close curs_proginfo
    deallocate curs_proginfo

end
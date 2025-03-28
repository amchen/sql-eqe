if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_UpdatePrtPerilMdlRgnId') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_UpdatePrtPerilMdlRgnId
end
go

create procedure absp_Migr_UpdatePrtPerilMdlRgnId
	@oldmdlRgnId integer,
	@newmdlRgnId integer,
	@peril       integer,
	@postfix     varchar(10),
	@notes       varchar(max)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version: MSSQL

Purpose:    This procedure is used to migrate table PRTPERIL when we have model region id changes.
            The first thing it does is make a backup copy of PRTPERIL appended by @postfix which should
            be the defect number (e.g. _00020332).
            The algorithm cursors through PRTPERIL records that match the old model region and peril id.
            If a record with the new model region doesn't already exist, insert it.
            Then delete the record with the old model region id.

Note:       PRTPERIL has a UNIQUE INDEX PRTPERIL_I1 ON PRTPERIL (PORT_ID, MDL_RGN_ID, PERIL_ID);

Example:    exec absp_Migr_UpdatePrtPerilMdlRgnId 
                @oldmdlRgnId=69,
                @newmdlRgnId=71,
                @peril=9,
                @postfix='_00020332',
                @notes='CZE Migrated Portfolios do not produce any results because it fails to set the correct mdl_rgn_id in PRTPERIL'
            

Returns:    Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  @oldmdlRgnId ^^  The old model region id.
##PD  @newmdlRgnId ^^  The new model region id.
##PD  @peril       ^^  The peril id.
##PD  @postfix     ^^  The postfix string to append to the backup table, this should be the defect number.
##PD  @notes       ^^  A description of the defect, usually the headline.
*/
as

begin

    set nocount on
    
    declare @me     varchar(50)
    declare @msg    varchar(max)
    declare @tbl    varchar(120)
    declare @portID integer

    -- set variables
    set @me = 'absp_Migr_UpdatePrtPerilMdlRgnId: '
    set @tbl = 'PRTPERIL' + @postfix

    set @msg = @me + 'Begin'
    execute absp_MessageEx @msg  

    set @msg = @me + 'Fix PRTPERIL for ' + @notes 
    execute absp_MessageEx @msg  

    if not exists (select 1 from SYS.TABLES where  NAME = @tbl) 
    begin
        execute absp_Migr_MakeCopyTable '', @postfix, '', 'PRTPERIL' 
    end
    else
    begin
        set @msg = @me + 'Table ' + @tbl + ' already exists.' 
        execute absp_MessageEx @msg 
    end

    declare curs1 cursor for
        select distinct PORT_ID  from PRTPERIL where MDL_RGN_ID = @oldmdlRgnId and PERIL_ID = @peril order by PORT_ID
    open curs1
    
		fetch next from curs1 into @portID
		while(@@fetch_status = 0) 
		begin
			-- insert the new MDL_RGN_ID for the PORT_ID
			-- if it does not already exist
			if not exists (select 1 from PRTPERIL where PORT_ID = @portID and MDL_RGN_ID = @newmdlRgnId and PERIL_ID = @peril)
			begin
				set @msg = 'Insert PRTPERIL values PORT_ID=' + cast(@portID  as char) + ', MDL_RGN_ID=' + cast(@newmdlRgnId as char) + ', PERIL_ID=' + cast(@peril as char)
				execute absp_MessageEx @msg  
				insert PRTPERIL (PORT_ID, MDL_RGN_ID, PERIL_ID) values (@portID , @newmdlRgnId, @peril)
			end 

			-- delete the old MDL_RGN_ID for the PORT_ID
			set @msg = 'Delete PRTPERIL where PORT_ID=' + cast(@portID  as char) + ', MDL_RGN_ID=' + cast(@oldmdlRgnId as char) + ', PERIL_ID=' + cast(@peril as char)
			execute absp_MessageEx @msg

			delete PRTPERIL where PORT_ID = @portID  and MDL_RGN_ID = @oldmdlRgnId and PERIL_ID = @peril
			fetch next from curs1 into @portID
		end
    
    close curs1
    deallocate curs1
    
    set @msg = @me + 'End' 
    execute absp_MessageEx @msg 
end

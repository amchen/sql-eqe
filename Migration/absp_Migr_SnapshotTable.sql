if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_SnapshotTable') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_SnapshotTable
end
go

create procedure absp_Migr_SnapshotTable
    @theTable  varchar(120),
    @tempPath  varchar(248) = '',
    @debugFlag integer = 1,
	@userName  varchar(100) = '',
	@password  varchar(100) = ''
as

 /*
 ##BD_BEGIN
 <font size ="3">
 <pre style="font-family: Lucida Console;" >
 ====================================================================================================
 DB Version:    MSSQL
 Purpose:

      This procedure invokes the absp_Migr_ReloadTableEx() procedure if the given table exists in CKPTCTRL
      and the corresponding _CKPT_ snapshot table exists.

 Returns:  Nothing

 ====================================================================================================
 </pre>
 </font>
 ##BD_END

 ##PD @theTable ^^  The table name for which the migration will take place.
 ##PD @tempPath ^^  The path of the temporary file used during migration
 ##PD @debugFlag ^^  The debug Flag
 ##PD  @userName ^^ The userName - required in case of SQL authentication
 ##PD  @password ^^ The password - required in case of SQL authentication

 */

begin
    set nocount on

    /*
        Migration of snapshot table
    */
    -- standard declares
    declare @me  varchar(25);   -- Procedure Name
    declare @sql varchar(max);  -- to handle sql type work

    declare @ckptKeyStr varchar(20);
    declare @newTable   varchar(100);
    declare @postfix    varchar(50);
    declare @sMsg       varchar(512);
    declare @CK         int;

    -- initialize variables
    set @me = 'absp_Migr_SnapshotTable: ' ;         -- set to my name Procedure Name
    set @sql = '';
	set @sMsg = @me + 'Begin';
    exec absp_MessageEx @sMsg

    -- Check for CKPTCTRL and CKPTINFO
    if not exists (select 1 from SYSOBJECTS where NAME = 'CKPTCTRL')
    begin
	set @sMsg = @me + 'CKPTCTRL not found.';
	exec absp_MessageEx @sMsg;
	set @sMsg = @me + 'End';
        exec absp_MessageEx @sMsg;
        return;
    end
    if not exists (select 1 from SYS.TABLES where Name = 'CKPTINFO')
	begin
        set @sMsg = @me + 'CKPTINFO not found.';
	exec absp_MessageEx @sMsg;
	set @sMsg = @me + 'End';
        exec absp_MessageEx @sMsg
        return;
    end;

    -- check for snapshot table
    if exists (select 1 from CKPTCTRL where TABLE_NAME = @theTable)
    begin
	declare cursCKPT  cursor fast_forward for select CKPT_KEY from CKPTINFO
	open cursCKPT
	fetch next from cursCKPT into @CK
	while(@@FETCH_STATUS=0)
        begin
            set @ckptKeyStr = ltrim(rtrim(str(@CK)));
            set @postfix = '_CKPT_' + @ckptKeyStr;
            set @newTable = ltrim(rtrim(@theTable)) + @postfix;

            -- migrate snapshot table
	    print 'migrate snapshot table'
            if exists (select 1 from SYS.TABLES where NAME = @newTable)
	    begin
		print 'reloading table'
                exec absp_Migr_ReloadTableEx @theTable, @tempPath, @newTable, @userName, @password;
	    end
            else
	    begin
		print 'creating table'
                exec absp_Migr_CreateTable @theTable, @newTable, 0 ;
            end
	    fetch next from cursCKPT into @CK
         end
	 close cursCKPT
	 deallocate cursCKPT
    end

    -------------- end --------------------
    set @sMsg = @me + 'End'
    exec absp_MessageEx @sMsg;
end;

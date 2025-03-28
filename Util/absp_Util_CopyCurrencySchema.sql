if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CopyCurrencySchema') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CopyCurrencySchema
end
go

create procedure absp_Util_CopyCurrencySchema @sourceCurrsKey int, @targetCurrsKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console" >
====================================================================================================
DB Version: MSSQL
Purpose:    This procedure copies an existing currency schema to another currency schema.

Returns:    Nothing.
====================================================================================================
</pre>
</font>
##BD_END
##PD  @sourceCurrsKey ^^ The currency schema key theat is to be copied.
##PD  @targetCurrsKey  ^^ THe currency schema key to which a schema is to be copied.

*/
as
begin

    declare @me varchar(max)
    declare @script varchar(max)
    declare @bValid int
    declare @msgText varchar(1000)
    declare @cd varchar(3)
    declare @eRate float(53)
    declare @vDate varchar(8)
    declare @display varchar(10)
    declare @usage varchar(32)
    declare @revID int
    declare @active varchar(1)
    declare @useCnt float(53)
    declare @inList varchar(1)

    -- set variables
    set @me = 'absp_Util_CopyCurrencySchema: '
    set @bValid = 1

    set @msgText = @me + 'Begin'
    exec absp_MessageEx @msgText 

    if not exists (select 1 from SYS.TABLES where  NAME = 'CURRINFO') 
    begin
        set @msgText = @me + 'Table CURRINFO does not exist!' 
        exec absp_MessageEx @msgText
        set @bValid = 0
    end  
    if not exists (select 1 from SYS.TABLES where NAME = 'EXCHRATE') 
    begin
        set @msgText = @me + 'Table EXCHRATE does not exist!' 
        exec absp_MessageEx @msgText
        set @bValid = 0
    end  
    if (@bValid = 1) 
    begin
        if not exists (select 1 from EXCHRATE where CURRSK_KEY = @sourceCurrsKey) 
        begin
            set @msgText = @me + 'Source currency key does not exist in EXCHRATE!' 
            exec absp_MessageEx @msgText
            set @bValid = 0
        end  
        if not exists (select 1 from EXCHRATE where CURRSK_KEY = @targetCurrsKey) 
        begin
            set @msgText = @me + 'Target currency key does not exist in EXCHRATE!' 
            exec absp_MessageEx @msgText
            set @bValid = 0
        end  
    end  

    if (@bValid = 1) 
    begin
        declare curs1 cursor  for 
            select CODE as e1, EXCHGRATE as e2, VALID_DAT as e3, DISPLAY as e4, USAGE as e5, REV_ID as e6, ACTIVE as e7, USECOUNT as e8, IN_LIST as e9
                from EXCHRATE where CURRSK_KEY = @sourceCurrsKey
        open curs1
        fetch curs1 into @cd, @eRate, @vDate, @display, @usage, @revID,@active,@useCnt,@inList
        while (@@fetch_status=0)
        begin
            if exists (select 1 from EXCHRATE where CURRSK_KEY = @targetCurrsKey and CODE = @cd) 
                update EXCHRATE set
                    EXCHGRATE=@eRate,
                    VALID_DAT=@vDate,
                    DISPLAY=@display,
                    USAGE=@usage,
                    REV_ID=@revID,
                    ACTIVE=@active,
                    USECOUNT=@useCnt,
                    IN_LIST=@inList
                    where CURRSK_KEY = @targetCurrsKey and CODE = @cd
            else
                insert EXCHRATE (CURRSK_KEY,CODE,EXCHGRATE,VALID_DAT,DISPLAY,USAGE,REV_ID,ACTIVE,USECOUNT,IN_LIST)
                         values (@targetCurrsKey, @cd, @eRate, @vDate, @display, @usage, @revID,@active,@useCnt,@inList)       
 
           fetch curs1 into @cd, @eRate, @vDate, @display, @usage, @revID,@active,@useCnt,@inList
         end 
    end  

    set @msgText = @me  + 'End' 
    exec absp_MessageEx @msgText
end

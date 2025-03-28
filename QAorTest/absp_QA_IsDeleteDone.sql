if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_QA_IsDeleteDone') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_IsDeleteDone;
end
go

create procedure  absp_QA_IsDeleteDone
     @isDone integer output,
     @nodeType varchar(20),
     @nodeName varchar(120),
     @nodeParentName varchar(120) = ''
as

/*
Valid Node Types:

CURRENCY
FOLDER
APORT
PPORT
RPORT
RAP
PROGRAM
ACCOUNT
POLICY
SITE
CASE
TREATY
*/

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure returns 0 (false) or 1 (true) if a node with the given name has been
               successfully deleted.

Returns:       Output parameter @isDone, 0 (false) or 1 (true).
====================================================================================================

</pre>
</font>
##BD_END

##PD  @isDone    ^^ The output parameter, 0 (false) or 1 (true).
##PD  @nodeType  ^^ Valid node types: CURRENCY, FOLDER, APORT, PPORT, RPORT, RAP, PROGRAM, ACCOUNT, POLICY, SITE, CASE, TREATY.
##PD  @nodeName  ^^ The name of the node (or POLICY_NUM or SITE_NUM).
##PD  @nodeParentName ^^ An optional parent portfolio name, only required if @nodeType is POLICY or SITE.

*/

begin

    declare @isDeleted integer;
    declare @portId integer;
    declare @errorMsg varchar(max);

    set @isDeleted = 1;
    set @errorMsg = 'Error calling absp_QA_IsDeleteDone: ';

    if (@nodeType = 'CURRENCY')
	begin
        if exists (select 1 from FLDRINFO where LONGNAME = @nodeName and CURR_NODE = 'Y')
            set @isDeleted = 0;
	end
    else if (@nodeType = 'FOLDER')
	begin
        if exists (select 1 from FLDRINFO where LONGNAME = @nodeName and CURR_NODE = 'N')
            set @isDeleted = 0;
	end
    else if (@nodeType = 'APORT')
	begin

        if exists (select 1 from APRTINFO where LONGNAME = @nodeName)
            set @isDeleted = 0;
	end
    else if (@nodeType = 'PPORT')
	begin
        if exists (select 1 from PPRTINFO where LONGNAME = @nodeName)
            set @isDeleted = 0;

	end
    else if (@nodeType = 'RPORT')
	begin

        if exists (select 1 from RPRTINFO where LONGNAME = @nodeName and MT_FLAG = 'N')
            set @isDeleted = 0;
	end
    else if (@nodeType = 'RAP')
	begin
        if exists (select 1 from RPRTINFO where LONGNAME = @nodeName and MT_FLAG = 'Y')
            set @isDeleted = 0;
	end
    else if (@nodeType = 'PROGRAM')
	begin

        if exists (select 1 from PROGINFO where LONGNAME = @nodeName and MT_FLAG = 'N')
            set @isDeleted = 0;

	end
    else if (@nodeType = 'ACCOUNT')
	begin

        if exists (select 1 from PROGINFO where LONGNAME = @nodeName and MT_FLAG = 'Y')
            set @isDeleted = 0;

	end

    else if (@nodeType = 'CASE')
	begin

        if exists (select 1 from CASEINFO where LONGNAME = @nodeName and MT_FLAG = 'N')
            set @isDeleted = 0;
	end
    else if (@nodeType = 'TREATY')
	begin

        if exists (select 1 from CASEINFO where LONGNAME = @nodeName and MT_FLAG = 'Y')
            set @isDeleted = 0;
	end
    else
	begin
        -- unsupported nodetype
        set @errorMsg = @errorMsg + 'Unsupported @nodeType ''' + @nodeType + '''';
		raiserror (@errorMsg, 18, 1);
	end

    set @isDone = @isDeleted;

end

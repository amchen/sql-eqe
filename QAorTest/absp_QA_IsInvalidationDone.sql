if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_QA_IsInvalidationDone') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_IsInvalidationDone;
end
go

create procedure absp_QA_IsInvalidationDone
    @isDone integer output,
    @nodeType varchar(20),
    @nodeName varchar(120),
    @nodeParentName varchar(120) = ''
as
/*
Valid Node Types:

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
               successfully invalidated.

Returns:       Output parameter @isDone, 0 (false) or 1 (true).
====================================================================================================

</pre>
</font>
##BD_END

##PD  @isDone    ^^ The output parameter, 0 (false) or 1 (true).
##PD  @nodeType  ^^ Valid node types: APORT, PPORT, RPORT, RAP, PROGRAM, ACCOUNT, POLICY, SITE, CASE, TREATY.
##PD  @nodeName  ^^ The name of the node (or POLICY_NUM or SITE_NUM).
##PD  @nodeParentName ^^ An optional parent portfolio name, only required if @nodeType is POLICY or SITE.

*/

begin

    declare @isInvalidated integer;
    declare @portId integer;
    declare @portKey integer;
    declare @policyKey integer;
    declare @siteKey integer;
    declare @errorMsg varchar(max);

    set @isInvalidated = 1;
    set @errorMsg = 'Error calling absp_QA_IsInvalidationDone: ';

    if (@nodeType = 'APORT')
    begin

        if exists (select 1 from APRTINFO where LONGNAME = @nodeName)
        begin
            select @portKey = APORT_KEY   from APRTINFO where LONGNAME = @nodeName;
            if exists (select 1 from ReportsDone where NodeKey = @portKey and NodeType=1 )
                set @isInvalidated = 0;
        end
        else
        begin
            set @errorMsg = @errorMsg + 'APORT node ''' + @nodeName + ''' not found';
            raiserror (@errorMsg, 18, 1);
        end
	end
    else if (@nodeType = 'PPORT')
    begin

        if exists (select 1 from PPRTINFO where LONGNAME = @nodeName)
        begin
            select  @portKey = PPORT_KEY  from PPRTINFO where LONGNAME = @nodeName;
            if exists (select 1 from ReportsDone where NodeKey = @portKey and NodeType=2 )
                set @isInvalidated = 0;
        end
        else
        begin
            set @errorMsg = @errorMsg + 'PPORT node ''' + @nodeName + ''' not found';
            raiserror (@errorMsg, 18, 2);
        end
	end
    else if (@nodeType = 'RPORT')
    begin

        if exists (select 1 from RPRTINFO where LONGNAME = @nodeName and MT_FLAG = 'N')
        begin
            select @portKey = RPORT_KEY  from RPRTINFO where LONGNAME = @nodeName and MT_FLAG = 'N';
            if exists (select 1 from ReportsDone where NodeKey = @portKey and NodeType=3)
                set @isInvalidated = 0;
        end
        else
        begin
            set @errorMsg = @errorMsg + 'RPORT node ''' + @nodeName + ''' not found';
            raiserror (@errorMsg, 18, 3);
        end
	end
    else if (@nodeType = 'RAP')
    begin

        if exists (select 1 from RPRTINFO where LONGNAME = @nodeName and MT_FLAG = 'Y')
        begin
            select @portKey = RPORT_KEY  from RPRTINFO where LONGNAME = @nodeName and MT_FLAG = 'Y';
            if exists (select 1 from ReportsDone where NodeKey = @portKey and NodeType=23)
                set @isInvalidated = 0;
        end
        else
        begin
            set @errorMsg = @errorMsg + 'RAP node ''' + @nodeName + ''' not found';
            raiserror (@errorMsg, 18, 4);
        end
	end
    else if (@nodeType = 'PROGRAM')
    begin

        if exists (select 1 from PROGINFO where LONGNAME = @nodeName and MT_FLAG = 'N')
        begin
            select @portKey = PROG_KEY  from PROGINFO where LONGNAME = @nodeName and MT_FLAG = 'N';
            if exists (select 1 from ReportsDone where NodeKey = @portKey and NodeType=7)
                set @isInvalidated = 0;
        end
        else
        begin
            set @errorMsg = @errorMsg + 'PROGRAM node ''' + @nodeName + ''' not found';
            raiserror (@errorMsg, 18, 5);
        end
	end
    else if (@nodeType = 'ACCOUNT')
    begin

        if exists (select 1 from PROGINFO where LONGNAME = @nodeName and MT_FLAG = 'Y')
        begin
            select @portKey = PROG_KEY  from PROGINFO where LONGNAME = @nodeName and MT_FLAG = 'Y';
            if exists (select 1 from ReportsDone where NodeKey = @portKey and NodeType=27)
                set @isInvalidated = 0
        end
        else
        begin
            set @errorMsg = @errorMsg + 'ACCOUNT node ''' + @nodeName + ''' not found';
            raiserror (@errorMsg, 18, 6);
        end
	end

    else if (@nodeType = 'CASE')
    begin

        if exists (select 1 from CASEINFO where LONGNAME = @nodeName and MT_FLAG = 'N')
        begin
            select @portKey = CASE_KEY  from CASEINFO where LONGNAME = @nodeName and MT_FLAG = 'N';
            if exists (select 1 from ReportsDone where NodeKey = @portKey and NodeType=10)
                set @isInvalidated = 0;
        end
        else
        begin
            set @errorMsg = @errorMsg + 'CASE node ''' + @nodeName + ''' not found';
            raiserror (@errorMsg, 18, 7);
        end
	end
    else if (@nodeType = 'TREATY')
    begin

        if exists (select 1 from CASEINFO where LONGNAME = @nodeName and MT_FLAG = 'Y')
        begin
            select @portKey = CASE_KEY  from CASEINFO where LONGNAME = @nodeName and MT_FLAG = 'Y';
            if exists (select 1 from ReportsDone where NodeKey = @portKey and NodeType=30)
                set @isInvalidated = 0;
        end
        else
        begin
            set @errorMsg = @errorMsg + 'TREATY node ''' + @nodeName + ''' not found';
            raiserror (@errorMsg, 18, 8);
        end
	end
    else
    begin

        -- unsupported nodetype
        set @errorMsg = @errorMsg + 'Unsupported @nodeType ''' + @nodeType + '''';
        raiserror (@errorMsg, 18, 9);
	end

    set @isDone = @isInvalidated

end

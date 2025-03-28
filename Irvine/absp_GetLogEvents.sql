if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_GetLogEvents') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetLogEvents
end
go

create procedure absp_GetLogEvents   @eventTypeBitFlags int,
 									 @userName varchar(25)='',
									 @nodeName varchar(120) = '',
									 @nodeType int = -1,
									 @extraKey1 int = 0,
									 @extraKey2 int = 0,
									 @includeChidren int = 0,
									 @fromDate char(25) = '',
									 @toDate char(250) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================

DB Version:    	MSSQL

Purpose:		This procedure returns a result set from STAEVENT consisting of all the logged events of the
            	specified node for the given user based on the specified event types (eventTypeBitFlags).

Parameters: 	eventTypeBitFlags ^^ The bit flags for event types. They are as follows:-
					0	Do not filter on event type
					1	Tree events
					2	User events
					4	Import events
					8	Analyze events
					16	System events
					32	Admin events
				nodeName ^^ do not filter on node name
				includeChidren ^^  0 = do not include, otherwise include
				userName ^^  The type of the node for which the parent node needs to be identified.
				fromDate ^^  from first event in log
				toDate ^^  to last event in log



Returns:       Single result set containing the following fields:

               1. STADEF_KEY
               2. START_DAT
               3. FINISH_DAT
               4. USER_NAME
               5. NODE_TYPE
               6. NODE_KEY
               7. PORT_ID
               8. POLICY_KEY
               9. SITE_KEY
               10.RBAT_KEY
               11.STADATA


====================================================================================================

</pre>
</font>
##BD_END

##PD  @eventTypeBitFlags ^^ The bit flags for event types.
##PD  @nodeName ^^ The node name for which the logged events are to be displayed
##PD  @nodeType ^^ The node type
##PD  @extraKey1 ^^ For PolicyKey
##PD  @extraKey2 ^^ For Site Key
##PD  @includeChidren ^^  If 0, child nodes are not returned
##PD  @userName ^^  The user whose logged events are to be displayed
##PD  @fromDate ^^  The start date from which the events in log are returned
##PD  @toDate ^^  The end date till which the events in log are returned

##RS	STADEF_KEY 	^^ Custom region name
##RS	START_DAT	^^ Start date of event in log
##RS	FINISH_DAT	^^ End date of event in log
##RS	USER_NAME	^^ User Name
#RS		NODE_TYPE 	^^ The Node Type
#RS		NODE_KEY	^^ The Node Key
#RS		PORT_ID 	^^ The Port Id
#RS		POLICY_KEY	^^ The Policy Key
#RS		SITE_KEY	^^ The Site Key
#RS		RBAT_KEY 	^^ The Rbat Key
#RS		STADATA		^^ The event details

*/
as
begin

set nocount on

	declare @me varchar(1000)
	declare @sql varchar(MAX)
	declare @bitValue bit
	declare @bitPos int
	declare @nodeKey int
	declare @whereFilter varchar(max)
	declare @eventFilter varchar(max)
	declare @eventNodeFilter varchar(max)
	declare @extraWhere varchar(max)
	declare @identitySqlOn varchar(100)
	declare @identitySqlOff varchar(100)
	declare @stDate varchar(4000);

	set @bitPos=0
	set @eventFilter=''
	set @eventNodeFilter=''
	set @extraWhere = ''
	set @whereFilter = ' where 1=1 '
	set @identitySqlOn = 'set identity_insert #TMPTBL on'
	set @identitySqlOff = 'set identity_insert #TMPTBL off'

	set @me = 'absp_GetLogEvents'
	execute absp_Util_Log_Info '-- Begin --',@me

	--create temporary table--
	if object_id('tempdb..#TMPTBL','u') is null
	begin
		select * into #TMPTBL from STAEVENT where 1=2
	end

	--create filter for Event types --
	while @eventTypeBitFlags<>0
	begin
		set @bitValue =  @eventTypeBitFlags % 2
		set @eventTypeBitFlags = @eventTypeBitFlags/2
		if @bitValue = 1
			if @bitPos=0 or @bitPos=1 or @bitPos=3
				set @eventFilter =@eventFilter + rtrim(ltrim(str(@bitPos+1))) + ','
			else
				set @eventNodeFilter = @eventNodeFilter + rtrim(ltrim(str(@bitPos+1))) + ','

		set @bitPos = @bitPos + 1
	end

	--For treeview, analyze and import events we set filter for NODE_NAME. For others we do not.
	if @eventFilter<>''
	begin
		set @eventFilter = ' and  STADEF.CATEGORY in(' + substring(@eventFilter,1,len(@eventFilter) -1) + ')'
		set @sql='select DISTINCT STAEVENT.STADEF_KEY from STAEVENT inner join STADEF ' +  ' on STADEF.STADEF_KEY = STAEVENT.STADEF_KEY ' + @eventFilter
		execute absp_Util_GenInList @eventFilter out,@sql
		set @eventFilter = ' and STAEVENT.STADEF_KEY '+ @eventFilter
	end

	if @eventNodeFilter<>''
	begin
		set @eventNodeFilter = ' and  STADEF.CATEGORY in(' + substring(@eventNodeFilter,1,len(@eventNodeFilter) -1) + ')'
		set @sql='select DISTINCT STAEVENT.STADEF_KEY from STAEVENT inner join STADEF ' +  ' on STADEF.STADEF_KEY = STAEVENT.STADEF_KEY ' + @eventNodeFilter
		execute absp_Util_GenInList @eventNodeFilter out,@sql
		set @eventNodeFilter = ' and STAEVENT.STADEF_KEY '+ @eventNodeFilter
	end

	-- filter for userName
	if 	@userName<>''
		set @whereFilter = @whereFilter + ' and  STAEVENT.USER_NAME = '''+@userName +''''

	-- filter for date
	set @stDate = 'substring(STAEVENT.START_DAT,1,8) + '' '' + substring(STAEVENT.START_DAT,9,2)+'':''+
				   substring(STAEVENT.START_DAT,11,2)+'':'' + substring(STAEVENT.START_DAT,13,2)'

	if 	@fromDate<>''
	begin
		set @fromDate = substring(@fromDate,1,8) + ' ' + substring(@fromDate,9,2)+':'+ substring(@fromDate,11,2)+':' + substring(@fromDate,13,2);
		set @whereFilter = @whereFilter + ' and  datediff ( ss, ' + @stDate + ',''' + rtrim(@fromDate)+''') <=0 ';
	end

	if 	@toDate<>''
	begin
		set @toDate = substring(@toDate,1,8) + ' ' + substring(@toDate,9,2)+':'+ substring(@toDate,11,2)+':' + substring(@toDate,13,2);
		set @whereFilter = @whereFilter + ' and  datediff ( ss, ' + @stDate + ',''' + rtrim(@toDate)+''') >=0 ';
	end

	--NodeName can be LIKE  the given nodeName--
	if charindex('*',@nodeName)>0
		set @extraWhere = ' and NODE_NAME like '''+ replace(@nodeName,'*','%') +''''
	else if @nodeName<>''
	begin
		execute @nodeKey = absp_Util_GetNodeKeyByName  @nodeName,@nodeType,@extraKey1
		set @extraWhere = ' and NODE_KEY = ' + str(@nodeKey)
 	end

 	--if nodeType is not given, search for all node types--
	if @nodeType<>-1
		set @extraWhere = @extraWhere +' and NODE_TYPE=' + str(@nodeType)
	else
	begin
		--Exclude policies and sites --
		set @extraWhere = @extraWhere +' and NODE_TYPE in(0,1,2,3,23,7,27,10,30)'
	end
	--Insert row for the node in temp table--
	if @eventNodeFilter<>''
    begin

    	set @sql =@identitySqlOn +' insert into #TMPTBL
			(STAEVT_KEY, STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA )
             select STAEVT_KEY, STAEVENT.STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA
               from STAEVENT ' + @whereFilter + @extraWhere + @eventNodeFilter

        if @eventFilter<>''
    		set @sql = @sql + ' union
    		select STAEVT_KEY, STAEVENT.STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA
    			from STAEVENT ' + @whereFilter  +  @eventFilter
    	end

    else
    begin
    	set @sql = @identitySqlOn +' insert into #TMPTBL
    			(STAEVT_KEY, STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA )
		  		select STAEVT_KEY, STAEVENT.STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA
		  			from STAEVENT ' + @whereFilter  + @eventFilter
   	end
   	set @sql = @sql + ' ' + @identitySqlOff
   	execute absp_Util_Log_Info @sql,@me
	execute (@sql)

    --If child nodes are to be included, find the child nodes that are logged for the given nodeName--
	if @nodeName<>'' and @includeChidren <>0
	begin
			if @nodeType=-1
					set @nodeType=0


			if @nodeType = 0 or @nodeType=12
			begin
				set @sql = 'insert into #TMPTBL
							(STAEVT_KEY, STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA )
							select distinct STAEVENT.STAEVT_KEY, STAEVENT.STADEF_KEY,STAEVENT.START_DAT,STAEVENT.FINISH_DAT,STAEVENT.USER_NAME,STAEVENT.NODE_NAME,STAEVENT.NODE_TYPE,STAEVENT.NODE_KEY,STAEVENT.PORT_ID,STAEVENT.POLICY_KEY,STAEVENT.SITE_KEY,STAEVENT.RBAT_KEY,STAEVENT.STADATA
						    from STAEVENT
							inner join FLDRMAP on STAEVENT.NODE_KEY=FLDRMAP.CHILD_KEY
							inner join #TMPTBL on FLDRMAP.FOLDER_KEY=#TMPTBL.NODE_KEY
							and #TMPTBL.NODE_TYPE in(0,12)
		                    and FLDRMAP.CHILD_TYPE = STAEVENT.NODE_TYPE ' + @whereFilter;
		         set @sql = @identitySqlOn + ' ' +  @sql + ' ' + @identitySqlOn
		         execute absp_Util_Log_Info @sql,@me
		         execute (@sql)
		         set @nodeType=1;
		    end

		    if @nodeType = 1
		    begin
		        set @sql = 'insert into #TMPTBL
		        			(STAEVT_KEY, STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA )
				        	select distinct STAEVENT.STAEVT_KEY, STAEVENT.STADEF_KEY,STAEVENT.START_DAT,STAEVENT.FINISH_DAT,STAEVENT.USER_NAME,STAEVENT.NODE_NAME,STAEVENT.NODE_TYPE,STAEVENT.NODE_KEY,STAEVENT.PORT_ID,STAEVENT.POLICY_KEY,STAEVENT.SITE_KEY,STAEVENT.RBAT_KEY,STAEVENT.STADATA
							from STAEVENT
							inner join APORTMAP on STAEVENT.NODE_KEY=APORTMAP.CHILD_KEY
							inner join #TMPTBL on APORTMAP.APORT_KEY=#TMPTBL.NODE_KEY
							and #TMPTBL.NODE_TYPE = 1
							and APORTMAP.CHILD_TYPE = STAEVENT.NODE_TYPE ' + @whereFilter;
				set @sql = @identitySqlOn + ' ' +  @sql + ' ' + @identitySqlOn
				execute absp_Util_Log_Info @sql,@me
		        execute (@sql)
		        set @nodeType=3; -- For Pports we need not find children
		    end

		    if @nodeType = 3 or @nodeType = 23
		    begin
				set @sql = 'insert into #TMPTBL
							(STAEVT_KEY, STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA )
						    select distinct STAEVENT.STAEVT_KEY, STAEVENT.STADEF_KEY,STAEVENT.START_DAT,STAEVENT.FINISH_DAT,STAEVENT.USER_NAME,STAEVENT.NODE_NAME,STAEVENT.NODE_TYPE,STAEVENT.NODE_KEY,STAEVENT.PORT_ID,STAEVENT.POLICY_KEY,STAEVENT.SITE_KEY,STAEVENT.RBAT_KEY,STAEVENT.STADATA
						    from STAEVENT
							inner join RPORTMAP on STAEVENT.NODE_KEY=RPORTMAP.CHILD_KEY
							inner join #TMPTBL on RPORTMAP.RPORT_KEY=#TMPTBL.NODE_KEY
							and #TMPTBL.NODE_TYPE in(3,23)
					    	and RPORTMAP.CHILD_TYPE = STAEVENT.NODE_TYPE ' + @whereFilter;
				set @sql = @identitySqlOn + ' ' +  @sql + ' ' + @identitySqlOn
			    execute absp_Util_Log_Info @sql,@me
		        execute (@sql)
			    set @nodeType=7; -- For Pports we need not find children
		    end

		    if @nodeType = 7 or @nodeType =27
		    begin
		    	set @sql ='insert into #TMPTBL
		    				(STAEVT_KEY, STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA )
						    select distinct STAEVENT.STAEVT_KEY, STAEVENT.STADEF_KEY,STAEVENT.START_DAT,STAEVENT.FINISH_DAT,STAEVENT.USER_NAME,STAEVENT.NODE_NAME,STAEVENT.NODE_TYPE,STAEVENT.NODE_KEY,STAEVENT.PORT_ID,STAEVENT.POLICY_KEY,STAEVENT.SITE_KEY,STAEVENT.RBAT_KEY,STAEVENT.STADATA
						    from STAEVENT
							inner join CASEINFO on STAEVENT.NODE_KEY=CASEINFO.CASE_KEY
							inner join #TMPTBL on CASEINFO.PROG_KEY=#TMPTBL.NODE_KEY
							and #TMPTBL.NODE_TYPE in(7,27)
							and STAEVENT.NODE_TYPE in (10,30) ' + @whereFilter;
				set @sql = @identitySqlOn + ' ' +  @sql + ' ' + @identitySqlOn
				execute absp_Util_Log_Info @sql,@me
		        execute (@sql)
			end
	end

    select STADEF_KEY,START_DAT,FINISH_DAT,USER_NAME,NODE_NAME,NODE_TYPE,NODE_KEY,PORT_ID,POLICY_KEY,SITE_KEY,RBAT_KEY,STADATA
	   from #TMPTBL
       order by START_DAT desc, STAEVT_KEY;

	execute absp_Util_Log_Info '-- End --',@me

end
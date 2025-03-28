if exists ( select 1 from sysobjects where name =  'absp_AutoTestGetRecordCount' and type = 'P' ) 
begin
    drop procedure absp_AutoTestGetRecordCount;
end

go

create procedure absp_AutoTestGetRecordCount	@mode			char(1), 
												@resultKey		int, 
												@testName   	char(100),
												@atRunObjType	char(2)  = 'NA',
												@showReport		char(1)
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:		This procedure records difference in record count in all tables in database, before
				and after execution of a test set, individual test cases or test steps, in AutoTestPandi
				
Returns:       	Nothing
====================================================================================================
</pre>
</font>
##BD_END
##PD  @mode			^^  With different modes of execution..  "I" initiates the process by creating 
						required tables (ATBEFORE_COUNT, ATAFTER_COUNT, ATRECREPORT).
						With mode "B" it saves record count of all tables in database in ATBEFORE_COUNT
						With mode "A" it saves record count of all tables in database in ATAFTER_COUNT
						and also stores difference in record for each tables in ATRECREPORT. apart from
						this info related to any tables being created or dropped is also saved in 
						ATRECREPORT table.
						
##PD  @resultKey	^^ 	Unique key generated while running Pandi.
##PD  @testName		^^  It could be any test set or test case or test step.
##PD  @atRunObjType	^^  Whether record diff. is for Prep Step ("PS") or Test Case ("TC") or CleanUp Step ("CS")
##PD  @showReport	^^  Whether we want to show report("Y")  or append differences in baseline file("N")						
*/

begin

   set nocount on
   
	declare @dbname nvarchar(128) 
	set @dbname = db_name()

	if (@mode = 'I') -- Initiate --
	begin
		if exists ( select 1 from sysobjects where name =  'ATBEFORE_COUNT' and type = 'U' ) 
		begin
			drop table ATBEFORE_COUNT;
		end

		create table ATBEFORE_COUNT(TABLENAME varchar(100), ROW_COUNT int, PRIMARY KEY (TABLENAME))

		if exists (select 1 from sysobjects where name =  'ATAFTER_COUNT' and type = 'U' ) 
		begin
			drop table ATAFTER_COUNT;
		end

		create table ATAFTER_COUNT(TABLENAME varchar(100), ROW_COUNT int, PRIMARY KEY (TABLENAME))

		if exists ( select 1 from sysobjects where name =  'ATRECREPORT' and type = 'U' ) 
		begin
			drop table ATRECREPORT;
		end

		create table ATRECREPORT( 
									  SL_NO 			int identity(1,1) not null,
									  AT_RUNOBJ_TYPE	varchar(2)		default  'NA',
									  TESTNAME			varchar(100)	not null,
									  RESULT_KEY		int				not null,
									  TABLENAME			varchar(120)		null,
									  DIFF				float  (53)		null,
									  DRP_CRT			varchar(1)		not null,
									  PRIMARY KEY (SL_NO, AT_RUNOBJ_TYPE, RESULT_KEY, TESTNAME)
									) on [primary]
	--end

	--else if (@mode = 'B')	-- Before run --
	--begin
		DBCC UPDATEUSAGE (@dbname) WITH NO_INFOMSGS

		truncate table	ATBEFORE_COUNT
		insert  into ATBEFORE_COUNT 
				select	sysobjects.name, rowcnt 
						from	sysindexes, sysobjects 
						where	sysindexes.id = sysobjects.id 
						and		sysobjects.xtype = 'U' 
						and		sysindexes.indid in (0,1) 
						and		sysobjects.name not IN ('ATBEFORE_COUNT', 'ATAFTER_COUNT', 'ATRECREPORT')
						order by sysobjects.name 
	end 

	if (@mode = 'A') 	-- After run --
	begin
		DBCC UPDATEUSAGE (@dbname) WITH NO_INFOMSGS

		truncate table	ATAFTER_COUNT
		insert  into ATAFTER_COUNT 
				select	sysobjects.name, rowcnt 
						from	sysindexes, sysobjects 
						where	sysindexes.id = sysobjects.id 
						and		sysobjects.xtype = 'U' 
						and		sysindexes.indid in (0,1)
						and		sysobjects.name not IN ('ATBEFORE_COUNT', 'ATAFTER_COUNT', 'ATRECREPORT')
						order by sysobjects.name 

		if @showReport = 'N' And @atRunObjType = 'PS' 
		begin
			-- When we do not want to view report Delete all pre - accumulated data 
			-- so that we deal only with data for single proc (Prep/ Proc Execute/ Cleanup)
			truncate table ATRECREPORT;	
		end ;
		
		-- Store row count difference --
		insert into ATRECREPORT (RESULT_KEY, TESTNAME, TABLENAME, DIFF, DRP_CRT, AT_RUNOBJ_TYPE)
					select	@resultKey, @testName, A.TABLENAME, (A.ROW_COUNT-B.ROW_COUNT), '', @atRunObjType 
					from	ATAFTER_COUNT A, ATBEFORE_COUNT B 
					where	A.TABLENAME = B.TABLENAME
					and		A.ROW_COUNT - B.ROW_COUNT <> 0
		

		-- Tables created after run --
		insert into ATRECREPORT (RESULT_KEY, TESTNAME, TABLENAME, DIFF, DRP_CRT, AT_RUNOBJ_TYPE)
					select @resultKey, @testName, TABLENAME, ROW_COUNT, 'C', @atRunObjType
					from ATAFTER_COUNT A  
					where NOT EXISTS(select TABLENAME 
									from ATBEFORE_COUNT B 
									Where A.TABLENAME = B.TABLENAME)

		-- Tables dropped after run --
		insert into ATRECREPORT (RESULT_KEY, TESTNAME, TABLENAME, DIFF, DRP_CRT, AT_RUNOBJ_TYPE)
					select @resultKey, @testName, TABLENAME, ROW_COUNT, 'D', @atRunObjType
					from ATBEFORE_COUNT A  
					where NOT EXISTS(select TABLENAME 
									from	ATAFTER_COUNT B 
									Where	A.TABLENAME = B.TABLENAME)
				
				
		truncate table ATBEFORE_COUNT;
		insert into ATBEFORE_COUNT select * from ATAFTER_COUNT order by TABLENAME

	end
end

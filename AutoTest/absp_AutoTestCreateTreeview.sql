if exists(select * from SYSOBJECTS where ID = object_id(N'absp_AutoTestCreateTreeview') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_AutoTestCreateTreeview
end
go

create  procedure absp_AutoTestCreateTreeview @password char(8) ,@reUseFlag int = 0 ,@nItems int = 2 ,@polsPerPport int = 1030 ,@sitesperPol int = 1 ,@createDate varchar(30) = 'CURR_DATE' ,@debug int = 0 ,@minimumGroupKey int = 1 ,@maximumGroupKey int = 1 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    mssql
Purpose:

This procedure will set up the treeview in a known, fixed format for treeview testing

Returns:       Recordset of what it did (min, max, counts of each node type)

====================================================================================================
</pre>
</font>
##BD_END

##PD  @password			^^  The user password. 
##PD  @reUseFlag		^^  If 0, always creates tree.  If 1, checks counts and only creates if no match.
##PD  @nItems			^^  The number of initial currency folders to create.  Limited to 3.
##PD  @polsPerPport		^^  The number of policies per primary pportfolio.
##PD  @sitesperPol		^^  The number of sites per policy. 
##PD  @createDate		^^  The date to stick into 'CREATE_DAT'  - defaults to now(). 
##PD  @debug			^^  Flag to turn on some messaging. 
##PD  @minimumGroupKey   	^^  The minimum group key to cycle through for ownership 
##PD  @maximumGroupKey   	^^  The maximum group key to cycle through for ownership 

*/
begin

   set nocount on
   
   declare @i int
   declare @j int
   declare @nCFolders int
   declare @nFolders int
   declare @nAports int
   declare @nPRports int
   declare @nProgs int
   declare @nCases int
   declare @nPortIds int
   declare @f1 real
   declare @f2 real
   declare @mustRegenFlag int
   declare @fldrType int
   declare @aportType int
   declare @pportType int
   declare @lportType int
   declare @rportType int
   declare @progType int
   declare @caseType int
   declare @currCFolderKey int
   declare @currFolderKey int
   declare @currAportKey int
   declare @currPportKey int
   declare @currLportKey int
   declare @currPortId int
   declare @currRPortKey int
   declare @currProgKey int
   declare @currCaseKey int
   declare @currCaseLayrKey int
   declare @currCaseReinKey int
   declare @minGroupKey int
   declare @maxGroupKey int
   declare @currGroupKey int
   declare @minCFolderKey int
   declare @maxCFolderKey int
   declare @countCFolders int
   declare @minFolderKey int
   declare @maxFolderKey int
   declare @countFolders int
   declare @minAportKey int
   declare @maxAportKey int
   declare @countAports int
   declare @minPportKey int
   declare @maxPportKey int
   declare @countPports int
   declare @minRportKey int
   declare @maxRportKey int
   declare @countRports int
   declare @minProgKey int
   declare @maxProgKey int
   declare @countProgs int
   declare @minCaseKey int
   declare @maxCaseKey int
   declare @countCases int
   declare @minPortId int
   declare @maxPortId int
   declare @countPortIds int
   declare @dtTm varchar(30)
   declare @dtTm1Yr varchar(100)
   declare @outName varchar(max)
   declare @outName2 varchar(max)
   declare @lastZip char(5)
   declare @mtFlag char(1)
   declare @curs cursor 
   declare @progkey int

   declare @HasIdentity	Integer 	-- Check if table has identity colunm --

   declare @func_absp_messageEx_par01 varchar(max)
   declare @curs0_CFK int
   declare @curs0 CURSOR
   declare @curs1_FK int
   declare @curs1 CURSOR
   declare @curs2_AK int
   declare @curs2 CURSOR
   declare @curs3_RK int
   declare @curs3 CURSOR
   declare @curs4_PGK int
   declare @curs4 CURSOR
   declare @curs5_PK int
   declare @curs5 CURSOR

   If @createDate = 'CURR_DATE' 
		set @createDate = CONVERT(VARCHAR,GetDate(),20)
   else
       set @createdate = LEFT(@createdate, 4)+'- '+SUBSTRING(@createdate, 5,2)+'- '+SUBSTRING(@createdate, 7,2)+' '+SUBSTRING(@createdate, 9,2)+':'+SUBSTRING(@createdate, 11,2)+':'+SUBSTRING(@createdate, 13,2)
       
   set @curs0 = cursor dynamic for select FOLDER_KEY as CFK from FLDRINFO where CURRSK_KEY > 0 order by FOLDER_KEY asc
   set @curs1 = cursor dynamic for select FOLDER_KEY as FK from FLDRINFO where CURRSK_KEY = 0 order by FOLDER_KEY asc
   set @curs2 = cursor dynamic for select APORT_KEY as AK from APRTINFO order by APORT_KEY asc
   set @curs3 = cursor dynamic for select RPORT_KEY as RK from RPRTINFO order by RPORT_KEY asc
   set @curs4 = cursor dynamic for select PROG_KEY as PGK from PROGINFO order by PROG_KEY asc
   set @curs5 = cursor dynamic for select PPORT_KEY as PK from PPRTINFO order by PPORT_KEY asc
   if @password <> 'AutoTest'
   begin
      return
   end
   set @minGroupKey = @minimumGroupKey
   set @maxGroupKey = @maximumGroupKey
   set @lastZip = ''
   set @mustRegenFlag = 0
   if @reUseFlag = 1
   begin
      select   @minCFolderKey = min(FOLDER_KEY), @maxCFolderKey = max(FOLDER_KEY), @countCFolders = count(FOLDER_KEY)  from FLDRINFO where FOLDER_KEY > 0 and CURRSK_KEY = 1
      set @nCFolders = @nItems
      if @minCFolderKey <> 1 or @maxCFolderKey <> @nItems or @countCFolders <> @nCFolders
      begin
         set @mustRegenFlag = 1
      end
      select   @minFolderKey = min(FOLDER_KEY), @maxFolderKey = max(FOLDER_KEY), @countFolders = count(FOLDER_KEY)  from FLDRINFO where FOLDER_KEY > 0 and CURRSK_KEY = 0
      set @f1 =(@nCFolders*1.0)/2.0
      set @f2 = @f1*((@nCFolders*1.0)+1.0)
      set @nFolders = @f2
      if @minFolderKey <> @nItems+1 or @maxFolderKey <> @nCFolders+@nFolders or @countFolders <> @nFolders
      begin
         set @mustRegenFlag = 1
      end
      select   @minAportKey = min(APORT_KEY), @maxAportKey = max(APORT_KEY), @countAports = count(APORT_KEY)  from APRTINFO
      set @f1 =(@nCFolders*1.0)/2.0
      set @f2 = @f1*((@nCFolders*1.0)+3.0)
      set @f1 =(@f2/2.0)*(@f2+1.0)
      set @nAports = @f1
      if @minAportKey <> 1 or @maxAportKey <> @nAports or @countAports <> @nAports
      begin
         set @mustRegenFlag = 1
      end
      select   @minPportKey = min(PPORT_KEY), @maxPportKey = max(PPORT_KEY), @countPports = count(PPORT_KEY)  from PPRTINFO
      set @f1 =(@nAports*1.0)/2.0
      set @f2 = @f1*((@nAports*1.0)+1.0)
      set @nPRports = @f2+@nAports
      if @minPportKey <> 1 or @maxPportKey <> @nPRports or @countPports <> @nPRports
      begin
         set @mustRegenFlag = 1
      end
      select   @minRportKey = min(RPORT_KEY), @maxRportKey = max(RPORT_KEY), @countRports = count(RPORT_KEY)  from RPRTINFO
      if @minRportKey <> 1 or @maxRportKey <> @nPRports or @countRports <> @nPRports
      begin
         set @mustRegenFlag = 1
      end
      select   @minProgKey = min(PROG_KEY), @maxProgKey = max(PROG_KEY), @countProgs = count(PROG_KEY)  from PROGINFO
      if @nItems = 1
      begin
         set @nProgs = 45
      end
      else
      begin
         if @nItems = 2
         begin
            set @nProgs = 864
         end
         else
         begin
            if @nItems = 3
            begin
               set @nProgs = 7020
            end
         end
      end
      if @minProgKey <> 1 or @maxProgKey <> @nProgs or @countProgs <> @nProgs
      begin
         set @mustRegenFlag = 1
      end
      select   @minCaseKey = min(CASE_KEY), @maxCaseKey = max(CASE_KEY), @countCases = count(CASE_KEY)  from CASEINFO
      if @nItems = 1
      begin
         set @nCases = 90
      end
      else
      begin
         if @nItems = 2
         begin
            set @nCases = 1728
         end
         else
         begin
            if @nItems = 3
            begin
               set @nCases = 14040
            end
         end
      end
      if @minCaseKey <> 1 or @maxCaseKey <> @nCases or @countCases <> @nCases
      begin
         set @mustRegenFlag = 1
      end

   end
   if @reUseFlag = 0 or @mustRegenFlag = 1
   begin
      if @nItems < 1
      begin
         set @nItems = 3
      end
      if @nItems > 3
      begin
         set @nItems = 3
      end
      if @polsPerPport < 1
      begin
         set @polsPerPport = 1
      end
      if @polsPerPport > 2020
      begin
         set @polsPerPport = 2020
      end
      if @sitesperPol < 1
      begin
         set @sitesperPol = 1
      end
      if @sitesperPol > 50
      begin
         set @sitesperPol = 50
      end
      if @minGroupKey < 0
      begin
         set @minGroupKey = 1
      end
      if @maxGroupKey < 0
      begin
         set @maxGroupKey = 1
      end
      if @debug > 0
      begin
         set @func_absp_messageEx_par01 = 'nItems ='+ str(@nItems)
         execute absp_MessageEx @func_absp_messageEx_par01
         set @func_absp_messageEx_par01 = 'polsPerPport ='+str(@polsPerPport)
         execute absp_MessageEx @func_absp_messageEx_par01
         set @func_absp_messageEx_par01 = 'sitesperPol ='+str(@sitesperPol)
         execute absp_MessageEx @func_absp_messageEx_par01
      end
      if exists(select 1 from sysobjects where name = 'On_delete_of_APORTMAP_delete_CURRMAP' and type = 'TR')
      begin
         drop trigger On_delete_of_APORTMAP_delete_CURRMAP
      end
      if exists(select 1 from sysobjects where name = 'On_delete_of_FLDRMAP_delete_CURRMAP' and type = 'TR')
      begin
         drop trigger On_delete_of_FLDRMAP_delete_CURRMAP
      end
      if exists(select 1 from sysobjects where name = 'On_insert_of_APORTMAP_insert_CURRMAP' and type = 'TR')
      begin
         drop trigger On_insert_of_APORTMAP_insert_CURRMAP
      end
      if exists(select 1 from sysobjects where name = 'On_insert_of_FLDRMAP_insert_CURRMAP' and type = 'TR')
      begin
         drop trigger On_insert_of_FLDRMAP_insert_CURRMAP
      end
      if exists(select 1 from sysobjects where name = 'On_update_of_APORTMAP_update_CURRMAP' and type = 'TR')
      begin
         drop trigger On_update_of_APORTMAP_update_CURRMAP
      end
      if exists(select 1 from sysobjects where name = 'On_update_of_FLDRMAP_update_CURRMAP' and type = 'TR')
      begin
         drop trigger On_update_of_FLDRMAP_update_CURRMAP
      end
      delete from CURRMAP
      delete from FLDRINFO where FOLDER_KEY > 0
      delete from FLDRMAP
      delete from APORTMAP
      delete from APRTINFO
      delete from PPRTINFO
      delete from RPRTINFO
      delete from RPORTMAP
      delete from PROGINFO
      delete from CASEINFO
      delete from CASELAYR
      delete from CASEREIN


      set @dtTm = @createDate
	  
      set @dtTm1Yr = Replace ( Replace ( Replace ( CONVERT(VARCHAR,dateadd(dd,365,@dtTm),20), '-', ''),':',''),' ','')
	  Set @dtTm = Replace ( Replace ( Replace (Convert(Varchar,@createDate,20), '-', ''),':',''),' ','')
	  
     
      if @debug > 0
      begin
         set @func_absp_messageEx_par01 = 'Create Date ='+@createDate
         execute absp_MessageEx @func_absp_messageEx_par01
      end
      set @fldrType = 0
      set @aportType = 1
      set @pportType = 2
      set @rportType = 3
      set @progType = 7
      set @lportType = 8
      set @caseType = 10
      set @currCFolderKey = 1
      set @currAportKey = 1
      set @currPportKey = 1
      set @currLportKey = 1
      set @currPortId = 1
      set @currRPortKey = 1
      set @currProgKey = 1
      set @currCaseKey = 1
      set @currCaseLayrKey = 1
      set @currCaseReinKey = 1
      set @currGroupKey = @minGroupKey
      set @i = 0
      while @i < @nItems
      begin         
         execute absp_Util_CreateNameWithKey @outName output,'CurrencyFolder',@currCFolderKey,4,0
         set @outName = @outName+' (under hidden root)'
		
		Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('FLDRINFO') , 'TableHasIdentity' ) ,-1)
		
		If @HasIdentity = 0
			Begin
				 insert into FLDRINFO (FOLDER_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,CURR_NODE,CURRSK_KEY) 
				                   values(@currCFolderKey,@outName,'AUTO',@dtTm,1,@currGroupKey,'Y',1)
			End
		If @HasIdentity = 1
			Begin
				set identity_insert  FLDRINFO on
				insert into FLDRINFO (FOLDER_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,CURR_NODE,CURRSK_KEY) 
				                   values(@currCFolderKey,@outName,'AUTO',@dtTm,1,@currGroupKey,'Y',1)
				set identity_insert  FLDRINFO off
			End


		Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('FLDRMAP') , 'TableHasIdentity' ) ,-1)

		If @HasIdentity = 0
			Begin
		         insert into FLDRMAP (FOLDER_KEY,CHILD_KEY,CHILD_TYPE) 
					              values(0,@currCFolderKey,@fldrType)
			End
		If @HasIdentity = 1
			Begin
				set identity_insert  FLDRMAP on
				insert into FLDRMAP (FOLDER_KEY,CHILD_KEY,CHILD_TYPE) 
					              values(0,@currCFolderKey,@fldrType)
				set identity_insert  FLDRMAP off
			End

         set @i = @i+1
         set @currCFolderKey = @currCFolderKey+1
         set @currGroupKey = @currGroupKey+1
         if @currGroupKey > @maxGroupKey
         begin
            set @currGroupKey = @minGroupKey
         end
      end

      set @currGroupKey = @minGroupKey
      open @curs0
      fetch next from @curs0 into @curs0_CFK
      while @@fetch_status = 0
      begin
         set @j = 0
         select   @currFolderKey = max(FOLDER_KEY)+1  from FLDRINFO
         while @j < @curs0_CFK
         begin

            execute absp_Util_CreateNameWithKey @outName output,'Folder',@currFolderKey,4,0
            execute absp_Util_CreateNameWithKey @outName2 output,' (under CurrencyFolder',@curs0_CFK,4,0
            set @outName = @outName+' '+@outName2+')'

			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('FLDRINFO') , 'TableHasIdentity' ) ,-1)
			
			If @HasIdentity = 1
				Begin
					set identity_insert  FLDRINFO on
						insert into FLDRINFO (FOLDER_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,CURR_NODE,CURRSK_KEY)
				                            values(@currFolderKey,@outName,'AUTO',@dtTm,1,@currGroupKey,'N',0)
					set identity_insert  FLDRINFO off
				End


            insert into FLDRMAP values(@curs0_CFK,@currFolderKey,@fldrType)
            set @currFolderKey = @currFolderKey+1

            execute absp_Util_CreateNameWithKey @outName output, 'Aport',@currAportKey,4,0
            set @outName = @outName+' '+@outName2+')'

			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('APRTINFO') , 'TableHasIdentity' ) ,-1)


			If @HasIdentity = 0
				Begin
			         insert into APRTINFO (APORT_KEY, LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY, REF_APTKEY)
				                   values(@currAportKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0)
				End
			If @HasIdentity = 1
				Begin
					set identity_insert  APRTINFO on
					insert into APRTINFO (APORT_KEY, LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY, REF_APTKEY)
				                   values(@currAportKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0)
					set identity_insert  APRTINFO off
				End

            insert into FLDRMAP values(@curs0_CFK,@currAportKey,@aportType)
            set @currAportKey = @currAportKey+1
            execute absp_Util_CreateNameWithKey @outName output,'Pport',@currPportKey,4,0
            set @outName = @outName+' '+@outName2+')'

            
			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('PPRTINFO') , 'TableHasIdentity' ) ,-1)

			If @HasIdentity = 0
				Begin
			insert into PPRTINFO (PPORT_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY, REF_PPTKEY)
				               values(@currPportKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0)
				End
			If @HasIdentity = 1
				Begin
					set identity_insert  PPRTINFO on
					insert into PPRTINFO (PPORT_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY, REF_PPTKEY)
		          		               values(@currPportKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0)
					set identity_insert  PPRTINFO off
				End
            
            insert into FLDRMAP values(@curs0_CFK,@currPportKey,@pportType)
            set @currPportKey = @currPportKey+1
            execute absp_Util_CreateNameWithKey @outName output,'Rport',@currRPortKey,4,0
            set @outName = @outName+' '+@outName2+')'
            -- odd guys normal; even MT
			if (@currRportKey = ((@currRportKey / 2) *2))  
            begin
			set @mtFlag = 'Y'
	            	set @rportType = 23
            end
			else
            begin
			set @mtFlag = 'N';
                	set @rportType = 3
            end 
            
			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('RPRTINFO') , 'TableHasIdentity' ) ,-1)


			If @HasIdentity = 0
				Begin
		            insert into RPRTINFO (RPORT_KEY, LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY, REF_RPTKEY,MT_FLAG)
									   values(@currRPortKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0,@mtFlag)
				End
			If @HasIdentity = 1
				Begin
					set identity_insert  RPRTINFO on
		            insert into RPRTINFO (RPORT_KEY, LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY, REF_RPTKEY,MT_FLAG)
									   values(@currRPortKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0,@mtFlag)
					set identity_insert  RPRTINFO off
				End
            

            insert into FLDRMAP values(@curs0_CFK,@currRPortKey,@rportType)
            set @currRPortKey = @currRPortKey+1
            set @j = @j+1
            set @currGroupKey = @currGroupKey+1

            if @currGroupKey > @maxGroupKey
            begin
               set @currGroupKey = @minGroupKey
            end

         end
--         commit work
         fetch next from @curs0 into @curs0_CFK
      end
      close @curs0
      Deallocate @curs0
      set @currGroupKey = @minGroupKey
      open @curs1
      fetch next from @curs1 into @curs1_FK
      while @@fetch_status = 0
      begin
         set @j = 0
         while @j < @curs1_FK
         begin

            execute absp_Util_CreateNameWithKey @outName output,'Aport',@currAportKey,4,0
            execute absp_Util_CreateNameWithKey @outName2 output,' (under Folder',@curs1_FK,4,0
            set @outName = @outName+' '+@outName2+')'

			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('APRTINFO') , 'TableHasIdentity' ) ,-1)

			If @HasIdentity = 0
				Begin
			         insert into APRTINFO (APORT_KEY, LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY, REF_APTKEY)
				                   values(@currAportKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0)
				End
			If @HasIdentity = 1
				Begin
					set identity_insert  APRTINFO on
					insert into APRTINFO (APORT_KEY, LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY, REF_APTKEY)
				                   values(@currAportKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0)
					set identity_insert  APRTINFO off
				End


            insert into FLDRMAP values(@curs1_FK,@currAportKey,@aportType)
            set @currAportKey = @currAportKey+1
            execute absp_Util_CreateNameWithKey @outName output,'Pport',@currPportKey,4,0
            set @outName = @outName+' '+@outName2+')'

        
			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('PPRTINFO') , 'TableHasIdentity' ) ,-1)
			
			If @HasIdentity = 1
				Begin
					set identity_insert  PPRTINFO on
					insert into PPRTINFO (PPORT_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY, REF_PPTKEY)
		          		               values(@currPportKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0)
					set identity_insert  PPRTINFO off
				End
        
            insert into FLDRMAP values(@curs1_FK,@currPportKey,@pportType)
            set @currPportKey = @currPportKey+1
            execute absp_Util_CreateNameWithKey @outName output,'Rport',@currRPortKey,4,0
            set @outName = @outName+' '+@outName2+')'
            -- odd guys normal; even MT
			if (@currRportKey = ((@currRportKey / 2) *2))  
            		begin
				set @mtFlag = 'Y'
	            		set @rportType = 23
            		end
			else
            		begin
				set @mtFlag = 'N';
                		set @rportType = 3
			end 
        
			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('RPRTINFO') , 'TableHasIdentity' ) ,-1)

			If @HasIdentity = 1
				Begin
					set identity_insert  RPRTINFO on
		            insert into RPRTINFO (RPORT_KEY, LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY, REF_RPTKEY,MT_FLAG)
									   values(@currRPortKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0,@mtFlag)
					set identity_insert  RPRTINFO off
				End
        
            insert into FLDRMAP values(@curs1_FK,@currRPortKey,@rportType)
            set @currRPortKey = @currRPortKey+1
            set @j = @j+1
            set @currGroupKey = @currGroupKey+1

            if @currGroupKey > @maxGroupKey
            begin
               set @currGroupKey = @minGroupKey
            end

         end
--         commit work
         fetch next from @curs1 into @curs1_FK
      end
      close @curs1
      Deallocate @curs1
      set @currGroupKey = @minGroupKey
      open @curs2
      fetch next from @curs2 into @curs2_AK
      while @@fetch_status = 0
      begin
         set @j = 0
         while @j < @curs2_AK
         begin

            execute absp_Util_CreateNameWithKey @outName output,'Pport',@currPportKey,4,0
            execute absp_Util_CreateNameWithKey @outName2 output,' (under Aport',@curs2_AK,4,0
            set @outName = @outName+' '+@outName2+')'

			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('PPRTINFO') , 'TableHasIdentity' ) ,-1)
			
			If @HasIdentity = 1
				Begin
					set identity_insert  PPRTINFO on
					insert into PPRTINFO (PPORT_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY, REF_PPTKEY)
		          		               values(@currPportKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0)
					set identity_insert  PPRTINFO off
				End

            insert into APORTMAP values(@curs2_AK,@currPportKey,@pportType)
            set @currPportKey = @currPportKey+1
            execute absp_Util_CreateNameWithKey @outName output,'Rport',@currRPortKey,4,0
            set @outName = @outName+' '+@outName2+')'
            -- odd guys normal; even MT
			if (@currRportKey = ((@currRportKey / 2) *2))  
            		begin
				set @mtFlag = 'Y'
			        set @rportType = 23		
			end
			else
            		begin
				set @mtFlag = 'N'
                		set @rportType = 3
			end 
			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('RPRTINFO') , 'TableHasIdentity' ) ,-1)

			If @HasIdentity = 1
				Begin
					set identity_insert  RPRTINFO on
		            insert into RPRTINFO (RPORT_KEY, LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY, REF_RPTKEY, MT_FLAG)
									   values(@currRPortKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0,@mtflag)
					set identity_insert  RPRTINFO off
				End

            insert into APORTMAP values(@curs2_AK,@currRPortKey,@rportType)
            set @currRPortKey = @currRPortKey+1
            set @j = @j+1
            set @currGroupKey = @currGroupKey+1

            if @currGroupKey > @maxGroupKey
            begin
               set @currGroupKey = @minGroupKey
            end

         end
--         commit work
         fetch next from @curs2 INTO @curs2_AK
      end
      close @curs2
      Deallocate @curs2
      set @currGroupKey = @minGroupKey
      open @curs3
      fetch next from @curs3 INTO @curs3_RK
      while @@fetch_status = 0
      begin
         set @j = 0
         
         while @j < 1+((@curs3_RK -1)%12)
         begin
            
            execute absp_Util_CreateNameWithKey @outName output,'Program',@currProgKey,4,0
            execute absp_Util_CreateNameWithKey @outName2 output,' (under Rport',@curs3_RK,4,0
            set @outName = @outName+' '+@outName2+')'

			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('PROGINFO') , 'TableHasIdentity' ) ,-1)

			If @HasIdentity = 1
				Begin
					set identity_insert  PROGINFO on

                   	insert into PROGINFO(PROG_KEY, LONGNAME, STATUS, CREATE_DAT, CREATE_BY, GROUP_KEY, LPORT_KEY, BCASE_KEY, CURRNCY_ID, IMPXCHRATE, INCEPT_DAT, EXPIRE_DAT, GROUP_NAM, BROKER_NAM, PROGSTAT, PORT_ID, MT_FLAG)
					values(@currProgKey,@outName,'AUTO',@dtTm,1,@currGroupKey,0,0,1,1,SUBSTRING(Ltrim(Rtrim(@dtTm)),1,8),SUBSTRING(Ltrim(Rtrim(@dtTm1Yr)),1,8),'None','None','Bound',0,'N')
					
					set identity_insert  PROGINFO off
				End

            insert into RPORTMAP values(@curs3_RK,@currProgKey,@progType)
            set @currProgKey = @currProgKey+1
            set @j = @j+1
            
            set @currGroupKey = @currGroupKey+1
            if @currGroupKey > @maxGroupKey

            begin
               set @currGroupKey = @minGroupKey
            end
         end
         fetch next from @curs3 INTO @curs3_RK
      end
      close @curs3
      Deallocate @curs3

    ------------------------------------------------------------------------------
	-- Step 5a: for each prog, set up MT_FLAG and TYPE to match parent RPORT
	------------------------------------------------------------------------------

     set @curs = cursor dynamic for 
            Select P.MT_FLAG,M.CHILD_KEY From RPRTINFO R,RPORTMAP M,PROGINFO P where R.RPORT_KEY = M.RPORT_KEY and R.MT_FLAG = 'Y'	and	M.CHILD_KEY = P.PROG_KEY and M.CHILD_TYPE = 7
            
		open @curs
		fetch next from @curs into @mtflag,@progkey
		while @@fetch_status = 0
		begin
		update proginfo set MT_FLAG = 'Y' where prog_key = @progkey
		update rportmap set child_type= 27 where CHILD_KEY=@progkey
        fetch next from @curs into @mtflag,@progkey
		end
		close @curs
		deallocate @curs
     ---------------------------------------------------------------------------------------
      open @curs4
      fetch next from @curs4 INTO @curs4_PGK
      while @@fetch_status = 0
      begin
         set @j = 0
         while @j < 1+((@curs4_PGK -1)%3)
         begin
            execute absp_Util_CreateNameWithKey @outName output,'Case',@currCaseKey,4,0
            execute absp_Util_CreateNameWithKey @outName2 output,' (under Progam',@curs4_PGK,4,0
            set @outName = @outName+' '+@outName2+')'

			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('CASEINFO') , 'TableHasIdentity' ) ,-1)

			If @HasIdentity = 1
				Begin
					set identity_insert  CASEINFO on
                    insert into CASEINFO(CASE_KEY, PROG_KEY, LONGNAME, STATUS, CREATE_DAT, CREATE_BY, TTYPE_ID, NUM_OCCS, AGG_LIMIT, USE_JGFACT, JUDGE_FACT, EVENT_TRIG, OCC_LIM, CIAGG_VAL, CIAGG_CC, CITRIG_VAL, CITRIG_CC, CIOCC_VAL, CIOCC_CC, INUR_ORDR, MT_FLAG)
					values(@currCaseKey,@curs4_PGK,@outName,'AUTO',@dtTm,1,1,0,0.0,'N',50,0.0,0.0,0.0,'USD',0.0,'USD',0.0,'USD',0.0,'N')
					
					set identity_insert  CASEINFO off
				End
			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('CASELAYR') , 'TableHasIdentity' ) ,-1)

			If @HasIdentity = 1
				Begin
					set identity_insert  CASELAYR on

                   	insert into CASELAYR (	CSLAYR_KEY, CASE_KEY, LNUMBER, OCC_LIMIT, OCC_ATTACH, PCT_ASSUME , PCT_PLACE, UW_PREM, CALCR_ID, AGG_LIMIT, AGG_ATTACH, SUBJ_PREM   ,ELOSSRATIO  ,ELOSS_BETA  ,ATTH_RATIO  ,AGG_RATIO  ,PR_CEDED, SS_MAXLINE  ,SS_RETLINE  ,COB_ID      ,TREATY_ID   ,PR_ATTACH   ,PR_LIMIT    ,PR_ASSUME   ,PR_NUM_POL  ,CLLIM_VAL   ,CLLIM_CC, CLATT_VAL   ,CLATT_CC    ,CLPREM_VAL  ,CLPREM_CC   ,CLAGG_VAL   ,CLAGG_CC    ,CLRET_VAL   ,CLRET_CC    ,CLAAT_VAL, CLAAT_CC    ,CLSPRM_VAL  ,CLSPRM_CC   ,CLPRA_VAL   ,CLPRA_CC    ,CLPRL_VAL   ,	CLPRL_CC    )
					values(@currCaseLayrKey,@currCaseKey,1,1+@currCaseKey%49,0,100,100,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1+@currCaseKey%49,'USD_K',0,'USD_K',0,'USD_K',0,'USD_K',0,'USD_K',0,'USD_K',0,'USD_K',0,'USD_K',0,'USD_K')
					
					set identity_insert  CASELAYR off
				End

			Select @HasIdentity= ISNULL(OBJECTPROPERTY ( object_id('CASEREIN') , 'TableHasIdentity' ) ,-1)

			If @HasIdentity = 1
				Begin
					set identity_insert  CASEREIN on

                   	insert into CASEREIN (CASERE_KEY, CASE_KEY, CSLAYR_KEY, REIN_NUM, PCT_OFPREM)
					values(@currCaseReinKey,@currCaseKey,@currCaseLayrKey,1,100)
					
					set identity_insert  CASEREIN off
				End

            update PROGINFO set BCASE_KEY = @currCaseKey  where PROG_KEY = @curs4_PGK and BCASE_KEY = 0
            set @currCaseKey = @currCaseKey+1
            set @currCaseLayrKey = @currCaseLayrKey+1
            set @currCaseReinKey = @currCaseReinKey+1
            set @j = @j+1
         end
         fetch next from @curs4 into  @curs4_PGK
      end
      close @curs4
      Deallocate @curs4
    ------------------------------------------------------------------------------
	-- Step 6a: for each Case, set up MT_FLAG to match parent Prog
	------------------------------------------------------------------------------
      set @curs = cursor dynamic for 
            Select P.MT_FLAG,P.PROG_KEY From CASEINFO C,PROGINFO P where C.PROG_KEY = P.PROG_KEY
            
		open @curs
		fetch next from @curs into @mtflag,@progkey
		while @@fetch_status = 0
		begin
		update CASEINFO set MT_FLAG = @mtflag where prog_key = @progkey

		fetch next from @curs into @mtflag,@progkey
		end
		close @curs
		deallocate @curs
      
      -------------------------------------------------------------------------------------
      open @curs5
      fetch next from @curs5 into @curs5_PK
      while @@fetch_status = 0
      begin

         update PPRTINFO set STATUS = 'ACTIVE'  where PPORT_KEY = @curs5_PK
         set @currPortId = @currPortId+2
         set @currLportKey = @currLportKey+1

         fetch next from @curs5 into  @curs5_PK
      end
      close @curs5
      Deallocate @curs5
     
   end

   select   @minCFolderKey = min(FOLDER_KEY), @maxCFolderKey = max(FOLDER_KEY), @countCFolders = count(FOLDER_KEY)  from FLDRINFO where FOLDER_KEY > 0 and CURRSK_KEY = 1
   select   @minFolderKey = min(FOLDER_KEY), @maxFolderKey = max(FOLDER_KEY), @countFolders = count(FOLDER_KEY)  from FLDRINFO where FOLDER_KEY > 0 and CURRSK_KEY = 0
   select   @minAportKey = min(APORT_KEY), @maxAportKey = max(APORT_KEY), @countAports = count(APORT_KEY)  from APRTINFO
   select   @minPportKey = min(PPORT_KEY), @maxPportKey = max(PPORT_KEY), @countPports = count(PPORT_KEY)  from PPRTINFO
   select   @minRportKey = min(RPORT_KEY), @maxRportKey = max(RPORT_KEY), @countRports = count(RPORT_KEY)  from RPRTINFO
   select   @minProgKey = min(PROG_KEY), @maxProgKey = max(PROG_KEY), @countProgs = count(PROG_KEY)  from PROGINFO
   select   @minCaseKey = min(CASE_KEY), @maxCaseKey = max(CASE_KEY), @countCases = count(CASE_KEY)  from CASEINFO
   execute absp_CreateTriggersOnCurrMap


End

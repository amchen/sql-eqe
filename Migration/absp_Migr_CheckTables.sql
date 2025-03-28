if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_CheckTables') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_CheckTables
end
go

create procedure absp_Migr_CheckTables
    @checkType   int         = 0,
    @checkLog    varchar(254)   = ''
as

/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

      This procedure compares the actual table schemas and index creation scripts for 
      all the application tables with the data dictionary (DICTTBL,DICTCOL, 
      DICTIDX) and returns 0 if correct else returns 1. In case of and error, a text file is 
      created (checkLog) with the differences in the table/index creation scripts
.
     
Returns:      0 if actual schema matches with the data dictionary of the application.
	      1 if actual schema does not match with the data dictionary of the application.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @checkType ^^  A flag which indicates if the scripts for the tables or indices are to be compared.
##PD  @checkLog ^^  The logfile name.

*/

begin
/*
    This proc checks actual table schemas against the data dictionary (DICTTBL, DICTCOL)
    and outputs error messages for table mismatches.

    Default checkType = 0, check tables only
            checkType = 1, check indices only
            checkType = 2, check tables and indices

    checkLog is the filename for output.
*/
    set nocount on

    declare @retCode     integer;
    declare @sText  varchar(max);
    declare @sDict  varchar(max);
    declare @sSys   varchar(max);
    declare @tname  varchar(120);
	declare @debugStr varchar(7999);
	declare @table Table(Msg varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS);
	declare @errFound bit;
    set @sText = '';
	set @errFound = 0;

    print cast(getdate() as varchar) + ': absp_Migr_CheckTables - Started';
	
    -- NOTE: we filter out client-only tables
    declare cursDctTbl cursor fast_forward for  select distinct  ltrim(rtrim ( TABLENAME )) as TBLNAME  from DICTTBL where LOCATION <> 'C'
    open cursDctTbl
    fetch next from cursDctTbl into @tname
		while(@@FETCH_STATUS=0)
        begin
        if (@checkType <> 1) 
		begin
            if exists ( select 1 from SYS.TABLES where NAME = @tname )
			begin
                -- Get the datadict schema
                exec absp_Util_CreateTableScript @sDict out, @tname

                -- Get the system schema
                exec absp_Util_CreateSysTableScript @sSys out, @tname

                if (@sDict <> @sSys) 
				begin
                    print cast(getdate() as varchar) + ': **** Table ' + @tname + ' schema does not match! ****' ;
					set @errFound = 1;
                    set @sText = 'DICT: ' + @sDict ;
                    Insert into @table values(@sText);
					set @sText = 'SYST: ' + @sSys  ;
					Insert into @table values(@sText);
				end
				else
				begin
                    print cast(getdate() as varchar) + ': **** Table ' + @tname + ' schema is correct! ****' ;
				end
			end
        end

        if (@checkType >= 1) 
		begin
			-- Get the datadict schema
			exec absp_Util_CreateTableScript @sDict out ,@tname, '','',2 ;

			-- Get the system schema
			exec absp_Util_CreateSysTableScript @sSys out,  @tname, '','',2;

			if (@sDict <> @sSys) 
			begin
				print cast(getdate() as varchar) + ': **** Index for table ' + @tname + ' does not match! ****' ;
				set @errFound = 1;
				set @sText = 'DICT: ' + @sDict ;
				Insert into @table values(@sText);
				set @sText = 'SYST: ' + @sSys  ;
				Insert into @table values(@sText);
			end
			else
			begin
                print cast(getdate() as varchar) + ': **** Index for table ' + @tname + ' is correct! ****' ;
			end
        end
	 fetch next from cursDctTbl into @tname
     end     -- end of the tables cursor

     close cursDctTbl
     deallocate cursDctTbl

	select Msg as Mismatches from @table;
	
    if @errFound > 0 
	begin
		if len(@checkLog) > 2 
		begin
       		declare currTbl cursor fast_forward for select Msg from @table
		open currTbl
		fetch next from currTbl into @sText
			while(@@FETCH_STATUS=0)
			begin
				set @debugStr = 'echo ' + @sText + ' >> ' + @checkLog 
				exec xp_cmdshell @debugStr;
			fetch next from currTbl into @sText
			end ;
		close currTbl
		deallocate currTbl
			print cast(getdate() as varchar) + ': absp_Migr_CheckTables - Errors!';
		end
		set @retCode = 1;
	end
    else
	begin
		print cast(getdate() as varchar) + ': absp_Migr_CheckTables - Success!';
		set @retCode = 0;
	end

    return @retCode

end

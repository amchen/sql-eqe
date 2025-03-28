if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_ProgramParts') and objectproperty(ID,N'isprocedure') = 1)
begin
	drop procedure absp_Migr_ProgramParts
end
go

create procedure absp_Migr_ProgramParts @oldProgKey int ,@newProgKey int,@linkedServerName varchar(200), @sourceDB varchar(200)
as
begin

	set nocount on
	declare @tabStep varchar(2)
	declare @inurKey int
	declare @tTypeID int
	declare @whereClause varchar(8000)
	declare @progkeyTrio varchar(8000)
	declare @whereClause2 varchar(8000)
	declare @progkeyTrio2 varchar(8000)
	declare @whereClause3 varchar(8000)
	declare @progkeyTrio3 varchar(8000)
	declare @newLayrKey int
	declare @iLayrKey int
	declare @newInurKey int
	declare @newKey int
	declare @sql nvarchar(max)
	declare @sql2 nvarchar(max)
	declare @fKey int
	declare @newFileKey int

	execute  absp_GenericTableCloneSeparator @tabStep output

   	set @whereClause = ' PROG_KEY = '+cast(@oldProgKey as char);
   	set @progkeyTrio = 'INT'+@tabStep+' PROG_KEY '+@tabStep+cast(@newProgKey as char);

	-- get each inur_key we need to clone
	set @sql='select INUR_KEY  from ' +@linkedServerName + '.[' + @sourceDB+'].dbo.INURINFO where  PROG_KEY = ' + cast(@oldProgKey as varchar(20))
	execute('declare cursInurInfo cursor global for '+@sql)

	open cursInurInfo;
	fetch next from cursInurInfo into @inurKey;
	while @@fetch_status = 0
	begin;
		set @whereClause = ' PROG_KEY = '+cast(@oldProgKey as varchar(20))+' and MT.INUR_KEY = '+cast(@inurKey as varchar(20));

    		-- clones the old inur_key to a new one
     		execute @newInurKey = dbo.absp_Migr_TableCloneRecords 'INURINFO',1,@whereClause,@progkeyTrio,@linkedServerName,@sourceDB

    		-- now for each layr associated with that inur_key
    		set @sql2='select INLAYR_KEY from ' +@linkedServerName + '.[' + @sourceDB+'].dbo.INURLAYR where INUR_KEY = ' + cast(@inurKey as varchar(20))
		execute('declare cursInurLayr cursor global for '+@sql2)
      		open cursInurLayr;
      		fetch next from cursInurLayr into @iLayrKey;
      		while @@fetch_status = 0
      		begin;
        		 set @whereClause2 = 'INLAYR_KEY = '+cast(@iLayrKey as varchar(20));
        		 set @progkeyTrio2 = 'INT'+@tabStep+' INUR_KEY '+@tabStep+cast(@newInurKey as varchar(20));
         		execute @newLayrKey = dbo.absp_Migr_TableCloneRecords 'INURLAYR',1,@whereClause2,@progkeyTrio2,@linkedServerName,@sourceDB

      			-- now for each layer we have to clone the pieces
         		set @whereClause3 = 'INLAYR_KEY = '+cast(@iLayrKey as char);
				set @progkeyTrio3 = 'INT'+@tabStep+' INUR_KEY '+@tabStep+cast(@newInurKey as char)+@tabStep+'INT'+@tabStep+' INLAYR_KEY '+@tabStep+cast(@newLayrKey as char);

         		execute dbo.absp_Migr_TableCloneRecords 'INUREXCL',1,@whereClause3,@progkeyTrio3,@linkedServerName,@sourceDB

      			-- At this point, LineofBusiness on the target database has been populated with resolved lookup IDs and tags
      			-- clone InurLineOfBusiness Table with new InLayerKey and new LineofBusinessID based on the matching LOB tag Name

         		fetch next from cursInurLayr into @iLayrKey;
      		end;
      		close cursInurLayr;
      		deallocate cursInurLayr;

    		-- the zero =all_layers= options
      		set @whereClause3 = 'INLAYR_KEY = 0 AND MT.INUR_KEY = '+cast(@inurKey as char);
      		set @progkeyTrio3 = 'INT'+@tabStep+' INUR_KEY '+@tabStep+cast(@newInurKey as char)+@tabStep+'INT'+@tabStep+' INLAYR_KEY '+@tabStep+cast(0 as char);

      		execute dbo.absp_Migr_TableCloneRecords 'INUREXCL',1,@whereClause3,@progkeyTrio3,@linkedServerName,@sourceDB
      		fetch next from cursInurInfo into @inurKey;
	end;
	close cursInurInfo;
	deallocate cursInurInfo;

end

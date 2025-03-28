if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CreateUS_POPWTCT') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_CreateUS_POPWTCT
end
go

create procedure absp_CreateUS_POPWTCT @fileFolder varchar(255), @isDebug int = 1
as
begin
	set nocount on

	declare @filePath varchar(255);
	declare @me varchar(255);
	declare @msg varchar(max);
	declare @sql varchar(max);
	declare @pwLat  float;
	declare @pwLon  float;
	declare @ezip varchar(6);
	declare @pt int;
	declare @logFile varchar(255)
    declare @createDt char(25)
    declare @retCode int;

	set @logFile = @fileFolder + '\CreateUS_POPWTCT.log';


	if @isDebug>0
	begin
		set @me = 'absp_CreateUS_POPWTCT';
		set @msg = 'Starting...';

        exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]'
		set @retCode = dbo.absxp_LogIt(@logFile, @createDt + '   ' + @msg);
	end


	-- create the query results table
	if exists (select 1 from sys.tables where name = 'US_POPWTCT')
	      drop table US_POPWTCT;

	 create table US_POPWTCT (
		PID	integer primary key identity(1,1),
	 	ENC_ZIP     varchar (6),
	 	NUMBLOCKS   integer default 0,
	 	POPWLAT     numeric (10,6) default 0,
	 	POPWLON     numeric (11,6) default 0,
	 	POPTOTAL    integer default 0
		);
	create index POPWTCT_I1 on US_POPWTCT (ENC_ZIP);
	create index POPWTCT_I2 on US_POPWTCT (POPTOTAL);


	if exists (select 1 from sys.tables where name = 'US_BLOCKS')
	        drop table US_BLOCKS;

	create table US_BLOCKS (STATE VARCHAR (2), COUNTY VARCHAR (3), TRACT VARCHAR (6), BLKGRP VARCHAR (1), BLOCK VARCHAR (4),  POP100 int, INTPTLAT numeric (10,6), INTPTLON numeric (11,6), ENC_ZIP VARCHAR (6)
	                               );

	create index BLOCKS_POP_I1 on US_BLOCKS (ENC_ZIP);
	create index BLOCKS_POP_I2 on US_BLOCKS (POP100);
	create index BLOCKS_POP_I3 on US_BLOCKS (INTPTLAT, INTPTLON);

    	begin try

    		-- load table --
	    	set @filePath = @fileFolder +  +'\\US_Blocks.txt';

	    	exec absp_Util_LoadData 'US_Blocks', @filePath, '\t'

	    	set @msg = 'Update US_POPWTCT table (ENC_ZIP, NUMBLOCKS, POPTOTAL)';

			if @isDebug>0
			begin
					exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]'
					set @retCode = dbo.absxp_LogIt(@logFile, @createDt + '   ' + @msg);
			end

	    	insert US_POPWTCT (ENC_ZIP, NUMBLOCKS, POPTOTAL)
	    		select ENC_ZIP, count(*) as NUMBLOCKS, sum(POP100) as POPTOTAL
	    		    from US_BLOCKS
	    		    where ENC_ZIP is not NULL and ENC_ZIP <> ''
	    		    group by ENC_ZIP
	    		    order by ENC_ZIP;


	    	select ENC_ZIP, POPTOTAL into #TMP_POPWTCT
	    	    from US_POPWTCT
	    	    where POPTOTAL <> 0
	    	    order by ENC_ZIP;

	    	set @msg = 'Update US_POPWTCT table (POPWLAT, POPWLON) ' ;
	    	if @isDebug>0
	    	begin
	    	        exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]'
					set @retCode = dbo.absxp_LogIt(@logFile, @createDt + '   ' + @msg);
			end


	    	declare curs1 cursor for
	    	    select ENC_ZIP as ezip, POPTOTAL as pt
	    	        from #TMP_POPWTCT
	    	        order by ENC_ZIP
	    	open curs1
	    	fetch curs1 into @ezip,@pt
	    	while @@fetch_status=0
	    	begin

				select @pwLat=(sum(POP100 * INTPTLAT)) / @pt, @pwLon=(sum(POP100 * INTPTLON)) / @pt
				from US_BLOCKS
				where ENC_ZIP = @ezip;

				set @msg = 'Update US_POPWTCT table set POPWLAT = ' + rtrim(cast(@pwLat as CHAR)) + ', POPWLON = ' + rtrim(cast(@pwLon as CHAR)) + ' for ENC_ZIP = ' + @ezip;


				if @isDebug>0
				begin
						exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]'
						set @retCode = dbo.absxp_LogIt(@logFile, @createDt + '   ' + @msg);
				end




				update US_POPWTCT set POPWLAT = @pwLat, POPWLON = @pwLon where ENC_ZIP = @ezip;
				fetch curs1 into @ezip,@pt
	    	end;
		close curs1
		deallocate curs1

	    	-- unload table to .bar file
	    	set @filePath = @fileFolder + '\\US_POPWTCT.bar';
	    	set @msg = @filePath;
			if @isDebug>0
			begin
					exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]'
					set @retCode = dbo.absxp_LogIt(@logFile, @createDt + '   ' + @msg);
			end

		 execute absp_Util_UnloadData
	    	    @unloadType='T',
	    	    @unloadText='US_POPWTCT',
	    	    @outFile=@filePath;


		end try
		begin catch
			select Error_Number() as Error_Number, Error_Message() as Error_Message
		end catch


	set @msg = 'Completed.';
	if @isDebug>0
	begin
	        exec absp_Util_GetDateString @createDt output, 'yyyy/mm/dd hh:nn:ss[sss]'
			set @retCode = dbo.absxp_LogIt(@logFile, @createDt + '   ' + @msg);
	end
end

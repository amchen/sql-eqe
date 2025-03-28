if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_ImportReportSource') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ImportReportSource
end
go

create procedure absp_ImportReportSource @ExposureKey int
as
BEGIN TRY

	declare @cnt int, @srcType nvarchar(50), @srcType2 nvarchar(50);
	declare @strExposureKey varchar(30), @strSrcID varchar(30);

	select @cnt = count(*) from ExposureFile where ExposureKey=@ExposureKey;
	select @srcType = case SourceType when 'X' then 'File' when 'T' then 'Database' when 'F' then 'File' end,
						@srcType2 = case SourceType when 'X' then 'Sheet' when 'T' then 'Table' end
						from ExposureFile
						where ExposureKey=@ExposureKey;

	begin
		declare @SrcID int, @sql nvarchar(max);
		declare curs1 cursor DYNAMIC for
			select SourceID from ExposureFile where ExposureKey=@ExposureKey order by SourceID;
		open curs1 FETCH NEXT FROM curs1 INTO @SrcID
		while @@FETCH_STATUS = 0
		begin
			SELECT @ExposureKey,'','';	-- blank line

			set @strExposureKey = cast(@ExposureKey as varchar(30));
			set @strSrcID = cast(@SrcID as varchar(30));

			set @sql='SELECT ' + @strExposureKey + ',''Source '+ @strSrcID +': '+@srcType+''''+
					 ',OriginalSourceName from ExposureFile where ExposureKey='+ @strExposureKey +' and SourceID='+ @strSrcID;
			execute (@sql);

			set @sql='SELECT ' + @strExposureKey + ',''Source '+ @strSrcID+': '+@srcType2+''''+',
							case Sourcetype
							when ''X'' then dbo.trim(substring(SourceName, CHARINDEX(''::'',SourceName,1)+2,100))
							when ''T'' then TableName
							else '''' end
						from ExposureFile where ExposureKey='+ @strExposureKey +' and SourceID='+ @strSrcID;
			execute (@sql);

			if (@cnt > 1)
			begin
				set @sql='SELECT ' + @strExposureKey + ',''Source '+ @strSrcID+': Category'''+',
							SourceCategory from ExposureFile where ExposureKey='+@strExposureKey+' and SourceID='+ @strSrcID;
				execute (@sql);
			end

			if exists(SELECT 1 FROM tempdb.dbo.sysobjects WHERE ID = OBJECT_ID(N'tempdb..#TableCounts')) drop table #TableCounts
			create table #TableCounts (ExposureKey int,InputSourceID int,InputSourceRowNum int,IsValid int);

			declare @Imp_curs2_TABLENAME VARCHAR(200), @counter int, @cntTotal int, @cntGood int;

			declare curs2 cursor DYNAMIC for
				select TABLENAME from dbo.absp_Util_GetTableList('Import.Count.Records');
			open curs2 FETCH NEXT FROM curs2 INTO @Imp_curs2_TABLENAME
			while @@FETCH_STATUS = 0
			begin
				if (@Imp_curs2_TABLENAME <> 'PolicyFilter')
				begin
					set @sql='insert #TableCounts select distinct ExposureKey,InputSourceID,InputSourceRowNum,IsValid from '+@Imp_curs2_TABLENAME + ' where ExposureKey=' + @strExposureKey+' and InputSourceID='+ @strSrcID;;
					execute(@sql)
				end
				FETCH NEXT FROM curs2 INTO @Imp_curs2_TABLENAME
			end;

			SELECT @cntTotal=COUNT(*)
			FROM (
					select distinct ExposureKey,InputSourceID,InputSourceRowNum,min(isValid) temp
					from #TableCounts
					group by ExposureKey,InputSourceID,InputSourceRowNum
				) tmpTotal;
			SELECT @cntGood=COUNT(*)
			FROM (
					select distinct ExposureKey,InputSourceID,InputSourceRowNum,min(isValid) temp
					from #TableCounts
					group by ExposureKey,InputSourceID,InputSourceRowNum
					having min(isValid)=1
				) tmpGood;

			Close curs2
			Deallocate curs2

			select @ExposureKey,'Source '+ @strSrcID+': Total records', @cntTotal;
			select @ExposureKey,'Source '+ @strSrcID+': Good records', @cntGood;
			select @ExposureKey,'Source '+ @strSrcID+': Error count', @cntTotal-@cntGood;

			FETCH NEXT FROM curs1 INTO @SrcID;
		end;
		Close curs1;
		Deallocate curs1;
	end
END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH

/*
--insert records from sproc
insert ImportStatReport exec absp_ImportReportSource 9
*/

if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_UpdateBatchJobStatus') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_UpdateBatchJobStatus
end
go

create procedure absp_UpdateBatchJobStatus @batchJobKeyList varchar(max), @status char(50)

as 

begin
	declare @sql varchar(max);
	declare @jobKey int
	declare @separator char(1)
	declare @separatorPosition int 
	declare @jobKeyValue varchar(100) 
	
	set @status = rtrim(@status);

	-- Cancel Running status is an intermediate state. When user cancels we set the status to Cancel Pending (CP)
	-- when the batch processor process the cancel request it sets the status to Cancel Running (CR)
	-- Here the CR and CP status can be treated as the same so we will locally set CR to CP
	
	if @status = 'CR'
		set @status = 'CP'
	if @status = 'RS'
	begin
		set @batchJobKeyList = @batchJobKeyList + ','
		
		while patindex('%,%' , @batchJobKeyList) <> 0 
		begin	
			select @separatorPosition =  patindex('%,%' , @batchJobKeyList)
			select @jobKeyValue = left(@batchJobKeyList, @separatorPosition - 1)
			set @jobKey = cast(@jobKeyValue as int)
			begin transaction
				if exists(select top 1 * from commondb..BatchJobStep where status in ('S','R') and BatchJobKey = @jobKey) 
					update commondb..BatchJob set Status = 'R' where BatchJobKey =  @jobKey 
				else 
					update commondb..BatchJob set Status = 'W' where BatchJobKey =  @jobKey
			commit transaction	

			select @batchJobKeyList = stuff(@batchJobKeyList, 1, @separatorPosition, '')
		end																
	end
	else
	begin
		if @status = 'PP'
			set @sql = 'update commondb..BatchJob set Status = ''' + rtrim(@status)+ ''' where Status in (''W'', ''WL'', ''R'') and BatchJobKey in (' + @batchJobKeyList + ')';
		else if @status = 'CP'
			set @sql = 'update commondb..BatchJob set Status = ''' + rtrim(@status)+ ''' where Status in (''W'', ''WL'', ''R'', ''PS'') and BatchJobKey in (' + @batchJobKeyList + ')';	
		else
			set @sql = 'update commondb..BatchJob set Status = ''' + rtrim(@status)+ ''' where BatchJobKey in (' + @batchJobKeyList + ')';
		
		begin transaction
		--print @sql
		exec  (@sql);
		commit transaction
	end

end


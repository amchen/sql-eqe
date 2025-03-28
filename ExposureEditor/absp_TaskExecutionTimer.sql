if exists ( select 1 from sysobjects where name = 'absp_TaskExecutionTimer ' and type = 'P' ) 
begin
   drop procedure absp_TaskExecutionTimer;
end
go

CREATE Procedure absp_TaskExecutionTimer @taskKey int, @debug int = 0
/*
 ##BD_BEGIN
 <font size ="3"> 
 <pre style="font-family: Lucida Console;" > 
 ====================================================================================================
 DB Version:    MSSQL
 Purpose:		
	This procedure acts like a task timer. If the task is ready to launch the timer will stop and
	let the task to be executed. Otherwise, the timer keeps holding the task execution. 
 Returns: Nothing
               
 ====================================================================================================
 </pre>
 </font>
 ##BD_END
 ##PD  @taskKey ^^  task key. 
*/

as
begin try
	set nocount on
	declare @sleepTime int	
	
	-- set sleep time in milli-seconds between each execution	
	set @sleepTime = 200;		
	
	-- while the waiting task exists (task might be deleted by other process),
	-- loop until task is ready to be executed
	while exists(select 1 from TaskInfo where taskkey = @taskKey and TaskTypeID in(4,5) and [status]='Waiting') 
	begin
		-- if no task is running, let the waiting task with lowest key to be launched and exit the loop
        if not exists( select 1 from TaskInfo where [Status]='Running'  and TaskTypeID in(4,5))
		begin			
			if exists( select 1 from TaskInfo where [status]='Waiting' having MIN(taskkey) = @taskKey)
			begin
			    -- this is to guard two or more waiting processes try to ge here at the same time 
			    -- while all the processes are in waiting and one of the processes is trying to set the status to 'Running'
			    if exists(select 1 from TaskInfo where [Status]='Running' and TaskTypeID in(4,5)) 
					exec absp_Util_Sleep @sleepTime
			    else
			    begin
					begin transaction
					update TaskInfo set [Status] = 'Running' where taskkey = @taskKey
					commit transaction
					
					--test loop until error is generated
					--while XACT_STATE() = 0
					--begin
					--	if @debug = 2 print 'task ready to be launched = ' + str(@taskKey)
					--end
					
					if @debug = 1 print 'task ready to be launched = ' + str(@taskKey)
					break;
				end				
            end
        end
        -- there is another task running, wait 200 ms 
		else
		begin
			if @debug = 1 print 'waiting 200ms ..., task = ' + str(@taskKey)
			exec absp_Util_Sleep @sleepTime;
		end 

	end -- while
end	try
begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch



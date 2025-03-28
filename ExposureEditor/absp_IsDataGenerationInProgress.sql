if exists ( select 1 from sysobjects where name = 'absp_IsDataGenerationInProgress ' and type = 'P' ) 
begin
   drop procedure absp_IsDataGenerationInProgress;
end
go

CREATE Procedure absp_IsDataGenerationInProgress @nodeKey int, @nodeType int = 0
as
begin
	set nocount on
	declare @IsTaskRunning int;
	set @isTaskRunning=0;
	
	--Check taskInfo to see if Job is Complete
	if @nodeType=2
	begin
		if exists(select 1 from TaskInfo where PportKey=@nodeKey and NodeType=@nodeType  and TaskTypeID in(4,5) and Status in('Waiting','Running'))
		begin
			return 1
		end
	end
	else
	begin
		if exists(select 1 from TaskInfo where ProgramKey=@nodeKey and NodeType=@nodeType and TaskTypeID in(4,5) and Status in('Waiting','Running'))
		begin
			return return 1
		end
	end
	--Check batchJob
	if @nodeType=2
	begin
		if exists(select 1 from BatchJob where PportKey=@nodeKey and NodeType=@nodeType and  JobTypeID = 24 and Status in('R', 'W', 'WL','PS','RS','RW','X'))
		begin
			return 1
		end
	end
	else
	begin
		if exists(select 1 from BatchJob where PportKey=@nodeKey and NodeType=@nodeType and JobTypeID = 24 and Status in('R', 'W', 'WL','PS','RS','RW','X'))
		begin
			return 1
		end
	end
	
	return  0
end 


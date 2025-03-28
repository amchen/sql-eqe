if exists(select * from SYSOBJECTS where ID = object_id(N'absclr_GetEnvironmentVariable') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absclr_GetEnvironmentVariable
end
go

create procedure absclr_GetEnvironmentVariable  @environValue varchar(255) out, @variableName nvarchar (255)
as
begin
	--Returns 0 on success--
   declare @rc varchar(255)
    exec systemdb.dbo.clr_Util_GetEnvironmentVariable @variableName,@rc out
	set @environValue=@rc
end;





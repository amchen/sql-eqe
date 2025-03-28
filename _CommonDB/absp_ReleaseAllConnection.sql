if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ReleaseAllConnection') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_ReleaseAllConnection
end
 go

create  procedure [dbo].[absp_ReleaseAllConnection]   
@databaseName VARCHAR(120)
as
SET NOCOUNT ON
Begin

declare @SQL VARCHAR(max),@SQL1 VARCHAR(max)

SET IMPLICIT_TRANSACTIONS  OFF 
Begin
  set @SQL = 'ALTER DATABASE ['+@databaseName +'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE'
  EXEC(@SQL)
  
  set @SQL1 ='ALTER DATABASE ['+@databaseName+ '] SET MULTI_USER'
  EXEC(@SQL1)
  
 --  exec sp_detach_db  @databaseName
End
   
End


GO



if exists(select * from SYSOBJECTS where ID = object_id(N'absp_DatabaseLogging') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_DatabaseLogging
end
 go
create procedure absp_DatabaseLogging @fileName char(255) 
as
begin
 
   set nocount on
   
  --This is an empty procedure 
   --Kept to maintain consistancy with ASA
   print 'absp_DatabaseLogging'
end
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdDriver_RS') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdDriver_RS;
end
go

create procedure absp_CupdDriver_RS
	@nodeKey int ,
	@nodeType int ,
	@parentKey int ,
	@parentType int ,
	@policyKey int = 0 ,
	@siteKey int = 0 ,
	@oldCurrsKey int ,
	@newCurrsKey int ,
	@doItFlag int = 1 ,
	@debugFlag int = 0 ,
	@sourceDB varchar(130)

/*
Purpose:	This procedure is a wrpapper of absp_CupdDriver to return a resultset to satisfy Hibernate.
*/
as

begin

   set nocount on;
   declare @cupdKey int;

   exec @cupdKey = absp_CupdDriver @nodeKey,@nodeType,@parentKey,@parentType,@policyKey,@siteKey,@oldCurrsKey,@newCurrsKey,@doItFlag ,@debugFlag,@sourceDB 
   select @cupdKey as cupdKey;
  
  
end

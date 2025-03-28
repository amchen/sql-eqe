if exists(select * from sysobjects where id = object_id(N'trimx') and objectproperty(id,N'IsScalarFunction') = 1)
begin
   drop function trimx;
end
go

create function dbo.trimx(@str varchar(max)) returns varchar(max)
as
begin
	return dbo.ltrimx(dbo.rtrimx(@str));
end

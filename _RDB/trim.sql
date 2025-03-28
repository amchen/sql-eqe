if exists(select * from sysobjects where id = object_id(N'trim') and objectproperty(id,N'IsScalarFunction') = 1)
begin
   drop function trim
end
go

create function dbo.trim(@string varchar(max))
returns varchar(max)
begin
    return ltrim(rtrim(@string))
end

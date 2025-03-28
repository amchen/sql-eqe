if exists(select * from sysobjects where id = object_id(N'rtrimx') and objectproperty(id,N'IsScalarFunction') = 1)
begin
   drop function rtrimx;
end
go

create function dbo.rtrimx(@str varchar(max)) returns varchar(max)
as
begin
	declare @trimchars varchar(10);
	set @trimchars = char(9)+char(10)+char(13)+char(32);
	set @str = reverse(dbo.ltrimx(reverse(@str)));
	return @str;
end

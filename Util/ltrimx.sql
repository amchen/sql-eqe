if exists(select * from sysobjects where id = object_id(N'ltrimx') and objectproperty(id,N'IsScalarFunction') = 1)
begin
   drop function ltrimx;
end
go

create function dbo.ltrimx(@str varchar(max)) returns varchar(max)
as
begin
	declare @trimchars varchar(10);
	set @trimchars = char(9)+char(10)+char(13)+char(32);
	set @str = substring(@str, patindex('%[^' + @trimchars + ']%', @str), 2123456789);
	return @str;
end

if exists(select * from sysobjects where id = object_id(N'lastindex') and objectproperty(id,N'IsScalarFunction') = 1)
begin
   drop function lastindex
end
go

create function dbo.lastindex(@string varchar(8000), @char char)
returns int
as
begin
	declare @index int,
	@start int
	select @string = rtrim(ltrim(@string))
	select @start = 0
	select @index = charindex(@char, @string, @start)
	while @index <> 0
	begin
	select @start = @index
	select @index = charindex(@char, @string, @start+1)
	end
	return (@start)
end

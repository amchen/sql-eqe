if exists(select 1 from sysobjects where id = object_id(N'split') and objectproperty(id,N'IsTableFunction') = 1)
begin
   drop function split
end
go

CREATE function [dbo].[Split](@string varchar(max),@delimiter char(1))
returns @tempTable TABLE ( RowNum int Identity(1,1), Items varchar(max))
begin
	declare @idx int;
	declare @slice varchar(max)
	
	select @idx=1;
	if LEN(@String)<1 or @String is null return;
	
	while @idx !=0
	begin
		set @idx=CHARINDEX(@delimiter,@string);
		if @idx!=0
			set @slice=LEFT (@string, @idx-1);
		else
			set @slice =@string
			
		if LEN(@slice)>0
			insert into @temptable(Items) values(dbo.trim(@slice));
		set @string=right(@string,LEN(@string)-@idx)
		if LEN(@string)=0 break
	end
    return
end
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ParseQuery') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_ParseQuery
end
go

create procedure absp_ParseQuery @parsedQuery varchar(max) out,@filterQuery varchar(max) 
as
begin
	set nocount on
	declare @pos int
	declare @stringToSearch varchar(10)
	declare @stringToReplace varchar(10)
	declare @query varchar(max) 
	
	set @stringToReplace =' @dbName..' 
	
	create table #T1 (StringToSearch varchar(10))
	insert into #T1 select ' from '  union select ' join ' union select ','  
	set @pos=-1
	

	if CHARINDEX (@stringToReplace,@filterquery)>0
	begin
		set @parsedQuery=@filterQuery
		return --it is adlready added
	end
	--remove extra spaces
	
	while (1=1)
	begin
		set @query =@filterQuery
		set @filterQuery=REPLACE(@filterQuery,'  ',' ')
		if @query = @filterQuery
			break
	end
 	
	declare c1 cursor for select StringToSearch from #T1
	open c1
	fetch c1 into @StringToSearch
	while @@FETCH_STATUS =0
	begin
	--PRINT @StringToSearch
		set @pos=-1	
		while (1=1)	
		begin	
			set @pos=CHARINDEX (@stringToSearch,@filterQuery,@pos+1)
			if @pos=0 break
			set @filterquery = LEFT(@filterQuery,@pos-1) + @stringToSearch + @stringToReplace + dbo.trim(SUBSTRING (@filterQuery,@pos+LEN(@stringToSearch)+1,LEN(@filterQuery)-@pos+LEN(@stringToSearch)))	
 		end
 			--print @filterquery

		fetch c1 into @StringToSearch
	end
	close c1
	deallocate c1
	set @parsedQuery= @filterquery

end

if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetTableInlistCount') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetTableInlistCount
end
 go
create procedure absp_GetTableInlistCount 
as
begin
  set nocount on
  declare @sql nvarchar(4000)  
  declare @tableName varchar(255)
  declare @perilId varchar(30)
  declare @count int
  declare @key varchar(1000)
  declare @countryId varchar(10)
  declare @id varchar(100)
  --declare @prevkey varchar(1000)
  
  create table #tmp (
               newkey varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS,
               id varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS,
               peril_id varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS
                    )
  --set @prevkey = ''

  declare curs cursor for 
	select TABLENAME, ltrim(rtrim(COUNTRY_ID)) COUNTRY_ID, MSTR_FIELD, SLAV_FLD01 
	from DICTLINK where LINKNUM > 0 and MSTR_FIELD not LIKE 'EQECEDE%' 
	order by TABLENAME, ltrim(rtrim(COUNTRY_ID)), LINKNUM
  open curs
  fetch next from curs into @tableName, @countryId, @id, @perilId
  while @@fetch_status =0
  begin
  
  if dbo.trim(@tableName) = 'PTL'
  begin
	  set @sql = 'select @count = count(IN_LIST) from ' + rtrim(ltrim(@tableName)) +
	   ' where PERIL_ID = ' + rtrim(ltrim(@perilId)) + ' and IN_LIST = ''Y'''
	   
	  exec sp_executesql @sql,N'@count int output', @count output
	  if @count = 0
	  begin
		fetch next from curs into @tableName, @CountryId, @id, @perilId
		continue
	  end 
  
  end
  
  
	set @key = ltrim(rtrim(@tableName)) + '|' + ltrim(rtrim(@countryId))
	--if @key <> @prevkey 
	--begin
	--	set @prevkey = @key
	insert into #tmp values (ltrim(rtrim(@key)), @id, @perilId)
	--end
	 

  
  fetch next from curs into @tableName, @CountryId, @id, @perilId
  end
  close curs
  deallocate curs
  
  select * from #tmp
end
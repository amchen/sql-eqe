if exists(select * from sysobjects where id = object_id(N'absp_Util_ListTreeViewPaths') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_Util_ListTreeViewPaths
end
go
create procedure absp_Util_ListTreeViewPaths @name varchar (255),@portType int = 2,@portKey  int = 0,@origName varchar (255) = '',@recurse  int = 0

/*
##BD_BEGIN
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    SQL2005
Purpose:       This procedure will give a hierarchial view of the parent nodes for a given node.

Returns: Nothing
              
====================================================================================================

</pre>
</font>
##BD_END
 
##PD  @name ^^ Name of the Portfolio for which the parent nodes are to be displayed.
##PD  @portType  ^^ Port Type of the Portfolio for which the parent nodes are to be displayed.
##PD  @portKey  ^^ Port Key of the Portfolio for which the parent nodes are to be displayed.
##PD  @origName  ^^ This contains bar-separated names to be displayed under the hierarchial view.
##PD  @recurse  ^^ A flag indicating whether the values given in origName are to be added to the hierarchy.

*/

as
begin
/*
This will list all of the treeview paths for a given Rportfolio or Pportfolio.

Usage:   
    call absp_Util_ListTreeViewPaths('', 2, 1234)   -- to list primary by key
    call absp_Util_ListTreeViewPaths('name', 2, 0)  -- to list primary by name or
    call absp_Util_ListTreeViewPaths('name', 2)     -- to list primary by name
    call absp_Util_ListTreeViewPaths('name')        -- to list primary by name

    call absp_Util_ListTreeViewPaths('', 3, 1234)   -- to list reins by key
    call absp_Util_ListTreeViewPaths('name', 3, 0)  -- to list reins by name or
    call absp_Util_ListTreeViewPaths('name', 3)     -- to list reins by name

    call absp_Util_ListTreeViewPaths('', 7, 1234)   -- to list Programs by key
    call absp_Util_ListTreeViewPaths('name', 7, 0)  -- to list Programs by name or
    call absp_Util_ListTreeViewPaths('name', 7)     -- to list Programs by name

    call absp_Util_ListTreeViewPaths('', 1, 1234)   -- to list Accum by key
    call absp_Util_ListTreeViewPaths('name', 1, 0)  -- to list Accum by name or
    call absp_Util_ListTreeViewPaths('name', 1)     -- to list Accum by name
*/

declare @portKey1 int
declare @portType1 int
declare @parent int
declare @parentKey int
declare @parentType int
declare @indent varchar(100)
--declare @origName char (255)
declare @i int
declare @tmp varchar(2000)
declare @tmp1 varchar(2000)
declare @sql varchar(max)
declare @fldrKey int
declare @aportKey int
declare @longname varchar(100)
declare @myName varchar(1000)
declare @linkKey int
declare @linkType int
declare @theName varchar(1000)

if @recurse = 0
begin
      print '\x0A====================='
      set @sql = 'absp_Util_ListTreeViewPaths('+'name='+case when @name is null then 'null' else rtrim(ltrim(@name))
   end+', portType='+rtrim(ltrim(str(@portType)))+', portKey='+rtrim(ltrim(str(@portKey)))+
   ', origName='+case when @origName is null then 'null' ELSE rtrim(ltrim(@origName))
   end+', recurse='+rtrim(ltrim(str(@recurse)))+')'
      execute absp_messageEx @sql
      print ' '
end


-- by name or by key?
if @portKey = 0 
	-- by name
begin
	if @portType = 0
		select @portKey = FOLDER_KEY  from FLDRINFO where LONGNAME = @name
	else if @portType = 1 
		select @portKey = APORT_KEY from APRTINFO where LONGNAME = @name
	else if @portType = 2 
		select @portKey = PPORT_KEY from PPRTINFO where LONGNAME = ltrim(rtrim(@name))
	else if @portType = 3 
		select @portKey =  RPORT_KEY from RPRTINFO where LONGNAME = @name
	else if @portType = 23 
		select @portKey = RPORT_KEY from RPRTINFO where LONGNAME = @name
	else if @portType = 7 
		select top 1 @portKey = PROG_KEY from PROGINFO where LONGNAME = @name
	else if @portType = 27 
		select top 1 @portKey = PROG_KEY  from PROGINFO where LONGNAME = @name
	else if @portType = 10 
		select top 1 @portKey = CASE_KEY from CASEINFO where LONGNAME = @name
	else if @portType = 30 
		select top 1 @portKey = CASE_KEY from CASEINFO where LONGNAME = @name
	else
		begin
			print 'The Type ' + str(@portType) + ' is not supported by this procedure'
			return
		end
end
else
	-- by key
begin
	--set @portKey = portKey;

	-- get the name
	if @portType = 0
		select @name = LONGNAME from FLDRINFO where FOLDER_KEY = @portKey;
	else if @portType = 1 
		select @name = LONGNAME from APRTINFO where APORT_KEY = @portKey;
	else if @portType = 2 
		select @name = LONGNAME from PPRTINFO where PPORT_KEY = @portKey;
	else if @portType = 3 
		select @name = LONGNAME from RPRTINFO where RPORT_KEY = @portKey;
	else if @portType = 7 
		select @name = LONGNAME from PROGINFO where PROG_KEY = @portKey;
	else if @portType = 10 
		select @name = LONGNAME from CASEINFO where CASE_KEY = @portKey;
	else
		begin
			print 'The Type ' + str(@portType) + ' is not supported by this procedure'
			return
		end
end 

if @recurse = 0 
	set @origName = ltrim(rtrim(@name))
--else
--	set @origName1 = @origName


-- Find the links
create table #LINKS (PORT_KEY int, PORT_TYPE int, LINK_KEY int, LINK_TYPE int, THE_NAME char(255)  COLLATE SQL_Latin1_General_CP1_CI_AS)


exec @parent = absp_FindNodeParent @parentKey output, @parentType output, @portKey, @portType
--message 'links absp_FindNodeParent , @parent, @parentKey, @parentType  = ', @parent, ' ', @parentKey, ' ', @parentType;

if @parent <> 2 and (@portType = 1 or @portType = 0) 
begin
	-- Folders accums can only link to Folders.   Find any other folders besides @parentKey
	declare curs2_foldrMapfldrInfo cursor fast_forward for
		select map.FOLDER_KEY, ltrim(rtrim(LONGNAME)) as theName from FLDRMAP map, FLDRINFO info
		where CHILD_KEY = @portKey and CHILD_TYPE = @portType
		  and map.FOLDER_KEY = info.FOLDER_KEY
		  and map.FOLDER_KEY <> @parentKey
	open curs2_foldrMapfldrInfo
	fetch next from curs2_foldrMapfldrInfo into @fldrKey, @longname
	while @@fetch_status = 0
    begin
		insert into #LINKS VALUES (@portKey, @portType, @fldrKey, 0, @longname)
		fetch next from curs2_foldrMapfldrInfo into @fldrKey, @longname
	end
    close curs2_foldrMapfldrInfo
    deallocate curs2_foldrMapfldrInfo
end 

if @portType = 2 or @portType = 3 
begin	
	-- Primary and Reinsurance can be linked to both Accums and Folders
    if @parentType = 0 
    begin
		declare curs3_foldrMapfldrInfo cursor fast_forward for
			select map.FOLDER_KEY, ltrim(rtrim(LONGNAME)) as theName from FLDRMAP map, FLDRINFO info
			where CHILD_KEY = @portKey and CHILD_TYPE = @portType
			  and map.FOLDER_KEY = info.FOLDER_KEY
			  and map.FOLDER_KEY <> @parentKey
		open curs3_foldrMapfldrInfo
		fetch next from curs3_foldrMapfldrInfo into @fldrKey, @longname
		while @@fetch_status = 0
		begin
			insert into #LINKS VALUES (@portKey, @portType, @fldrKey, 0, @longname)
			fetch next from curs3_foldrMapfldrInfo into @fldrKey, @longname
		end
		close curs3_foldrMapfldrInfo
		deallocate curs3_foldrMapfldrInfo

		declare curs4_aportMapaprtInfo cursor fast_forward for
			select map.APORT_KEY, ltrim(rtrim(LONGNAME)) as theName from APORTMAP map, APRTINFO info 
			where CHILD_KEY = @portKey and CHILD_TYPE = @portType
			  and map.APORT_KEY = info.APORT_KEY
		open curs4_aportMapaprtInfo
		fetch next from curs4_aportMapaprtInfo into @aportKey, @longname
		while @@fetch_status = 0
		begin
			insert into #LINKS VALUES (@portKey, @portType, @aportKey, 0, @longname)
			fetch next from curs4_aportMapaprtInfo into @aportKey, @longname
		end
		close curs4_aportMapaprtInfo
		deallocate curs4_aportMapaprtInfo

    end
	else
    begin
		declare curs5_aportMapaprtInfo cursor fast_forward for
			select map.APORT_KEY, ltrim(rtrim(LONGNAME)) as theName from APORTMAP map, APRTINFO info 
			where CHILD_KEY = @portKey and CHILD_TYPE = @portType
			  and map.APORT_KEY = info.APORT_KEY
			  and map.APORT_KEY <> @parentKey
		open curs5_aportMapaprtInfo
		fetch next from curs5_aportMapaprtInfo into @aportKey, @longname
		while @@fetch_status = 0
		begin
			insert into #LINKS VALUES (@portKey, @portType, @aportKey, 0, @longname)
			fetch next from curs5_aportMapaprtInfo into @aportKey, @longname
		end
		close curs5_aportMapaprtInfo
		deallocate curs5_aportMapaprtInfo

		declare curs6_foldrMapfldrInfo cursor fast_forward for
			select map.FOLDER_KEY, ltrim(rtrim(LONGNAME)) as theName from FLDRMAP map, FLDRINFO info 
			where CHILD_KEY = @portKey and CHILD_TYPE = @portType
			  and map.FOLDER_KEY = info.FOLDER_KEY
		open curs6_foldrMapfldrInfo
		fetch next from curs6_foldrMapfldrInfo into @fldrKey, @longname
		while @@fetch_status = 0
		begin
			insert into #LINKS VALUES (@portKey, @portType, @fldrKey, 0, @longname)
			fetch next from curs6_foldrMapfldrInfo into @fldrKey, @longname
		end
		close curs6_foldrMapfldrInfo
		deallocate curs6_foldrMapfldrInfo
	end 
end 

if @portType = 7 
begin
	-- Programs can only link to Reinsurance Portfolios
		declare curs7_rportMaprprtInfo cursor fast_forward for
			select map.RPORT_KEY, ltrim(rtrim(LONGNAME)) as theName from RPORTMAP map, RPRTINFO info 
			where CHILD_KEY = @portKey and CHILD_TYPE = @portType
			  and map.RPORT_KEY <> @parentKey
			  and map.RPORT_KEY = info.RPORT_KEY
		open curs7_rportMaprprtInfo
		fetch next from curs7_rportMaprprtInfo into @fldrKey, @longname
		while @@fetch_status = 0
		begin
			insert into #LINKS VALUES (@portKey, @portType, @fldrKey, 0, @longname)
			fetch next from curs7_rportMaprprtInfo into @fldrKey, @longname
		end
		close curs7_rportMaprprtInfo
		deallocate curs7_rportMaprprtInfo
end 

-- find the parent

-- init the loop
set @parentKey = @portKey
set @parentType = @portType
set @parent = 0

if @parentKey is NULL or @name is NULL or len(@name) = 0 
begin
	print 'Portfolio or program not found';

	if @portKey is null 
		 print '@portKey is null' 
    else 
		print '@portKey=' + str(@portKey) 	
	return
end 


-- create a table to hold the names
create table #NAMES (ROW int IDENTITY, MY_NAME char(255)  COLLATE SQL_Latin1_General_CP1_CI_AS)

--message 'name = ', @name;

if @recurse <> 0 
begin
	-- @origName contains bar-separated names.   Add each one to #NAMES, except the last.
	set @tmp1 = ltrim(rtrim(@origName))
	set @i = CHARINDEX('|',@tmp1)
	while @i > 0 
    begin
		set @tmp = left(@tmp1, @i-1);
		insert into #NAMES (MY_NAME) values (@tmp);

		 set @tmp1 = SUBSTRING(@tmp1, @i+1, LEN(@tmp1) -@i+1)
		set @i = CHARINDEX('|',@tmp1)
	end 

end 

insert into #NAMES (MY_NAME) values (@name);

while @parent <> 2 and @parent >= 0 
begin

	set @portKey = @parentKey;
	set @portType = @parentType;
	exec @parent = absp_FindNodeParent @parentKey output, @parentType output, @portKey, @portType
	--message 'absp_FindNodeParent , @portKey, portType, @parent, @parentKey, @parentType  = ', @portKey, ' ', portType, ' ',@parent, ' ', @parentKey, ' ', @parentType;

	if @parentType = 7 
		select @name = LONGNAME from PROGINFO where PROG_KEY = @parentKey;
	else if @parentType = 3 
		select @name = LONGNAME from RPRTINFO where RPORT_KEY = @parentKey;
	if @parentType = 1 
		select @name = LONGNAME from APRTINFO where APORT_KEY = @parentKey;
	if @parentType = 0 
		select @name = LONGNAME from FLDRINFO where FOLDER_KEY = @parentKey;

	--message 'name = ', @name;
	if  @portKey <> @parentKey or @portType <> @parentType 
		insert into #NAMES (MY_NAME) values (@name);
		
end 


-- list the names in reverse order, indenting more each name, like this:
-- Tree Path =
--     CurrencyName
--        FolderName
--          PortfolioName

set @name = ''
set @indent = ''
print 'Tree Path = '
declare curs1_names cursor fast_forward for
	select ltrim(rtrim(MY_NAME)) as MY_NAME from #NAMES order by ROW desc
open curs1_names
fetch next from curs1_names into @myName
while @@fetch_status = 0
begin
	set @indent = @indent + '   '
	print @indent + ltrim(rtrim(@myName))
	fetch next from curs1_names into @myName
end
close curs1_names
deallocate curs1_names


-- List the links
--if recurse = 0 and (select count(*) from #LINKS) > 0 then message '\nOther Links'; end if;
if (select count(*) from #LINKS) > 0 
	print 'Other Links'


declare curs8_links cursor fast_forward for
	select PORT_KEY, PORT_TYPE, LINK_KEY, LINK_TYPE, THE_NAME from #LINKS
open curs8_links
fetch next from curs8_links into @portKey1, @portType1, @linkKey, @linkType, @theName
while @@fetch_status = 0
begin
	--message 'PORT_KEY=',PORT_KEY,' PORT_TYPE=', PORT_TYPE,' LINK_KEY=',LINK_KEY,' LINK_TYPE=',LINK_TYPE;
	-- recurse to print this link path
	set @origName = ltrim(rtrim(@origName)) + '|' + ltrim(rtrim(@theName))
	exec absp_Util_ListTreeViewPaths '', @linkType, @linkKey, @origName, 1
    fetch next from curs8_links into @portKey1, @portType1, @linkKey, @linkType, @theName
end 
close curs8_links
deallocate curs8_links

end
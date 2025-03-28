if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetUniqueName') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetUniqueName
end
 go

create procedure absp_GetUniqueName @ret_nextName char(120) output ,@currentName char(120),@tableName char(120),@nameField char(12),@maxBaseName int =110 

/* 
##BD_BEGIN  
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

This procedure returns a unique name in an OUT parameter for the given column value of a table based on the currentName.

Returns:      Nothing

=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @ret_nextName ^^ This is an OUTPUT parameter where the unique name for the given column value of a table based on the currentName is returned.
##PD  @currentName ^^ The name from which the unique name is to be created.
##PD  @tableName ^^ The tablename for which the uniquename is to be created.
##PD  @nameField ^^ The field name for which the unique name is to be created.
##PD  @maxBaseName ^^ The maximum length of the unique name that is to be created.

*/
as
begin
	set nocount on

	declare @baseName 	varchar	(120)
	declare @cnt1 		int
	declare @n2 		int
	declare @n3 		int
	declare @n4 		int
	declare @n5 		int
	declare @r 		int
	declare @cpycode 	varchar	(10)
	declare @curNum 	char	(8)
	declare @prevNum 	varchar	(255)
	declare @len 		int
	declare @cpyCodeStr	varchar	(10)
	declare @ssql 		nvarchar(2000)
  	declare @errMsg		varchar	(2000)
  	declare @exists int

begin try	  	
  	-- this will allow for up to 999 copies of even the longest name
  	
  	--Check if the name exists in the currenct CF. Return the same name if it does not--
  	set @exists=0
  	set @ssql = 'select @exists = 1 from ' + dbo.trim(@tableName) + ' where ' + dbo.trim(@nameField) + ' = ''' + dbo.trim(@currentName) +''''
  	execute sp_executesql @ssql,N'@exists int output',@exists output
  	
  	if @exists=0 
  	begin
  		set @ret_nextName = @currentName
  		return
  	end
  	
	set @baseName = rtrim(ltrim(left(@currentName,@maxBaseName)))
	set @ret_nextName = @baseName
	set @cnt1 = 1
	set @n2 = 1
	set @cpycode = ' (copy '

	-- we see if it is already a copy n and if so just bump n
	set @n3 = dbo.lastindex(@baseName, @cpycode) - len(@cpycode)
	-- we need to see the if the name is ends with (Copy X) or we have more at end
	-- we need to get last occurance of (Copy X)
	set @n5 = dbo.lastindex(@currentName, ')')
	
	-- if n3 > 0 then  it is a copy
	if @n3 > 0 and @n5 = len(@currentName)
	begin
		-- find what n is
		set @curNum = substring(@baseName,@n3+len(@cpycode),len(@baseName) -@n3+len(@cpycode))
		set @n4 = charindex(')',@curNum)

		-- if we can find it, then increment it
		if @n4 > 0
		begin

			-- SDG__00011355 -- insure the string after '(copy ' is a number
			set @prevNum = left(@curNum,@n4 -1)
			exec @r = absp_Util_IsNumeric @prevNum
         
			if @r = 1
			begin
				-- KDT 26 May 2005: if there is no match, do not want to increase the number.  
				-- E.g. "Wind_Quake Sample Test (copy 14)" is not found then just    
				-- return it as "Wind_Quake Sample Test (copy 14)" 
				-- instead of "Wind_Quake Sample Test (copy 15)"
				--set @n2= 1 + cast(@prevNum as int);

				set @n2 = cast(@prevNum as int)

				-- set things up so the next part just works
				set @baseName = left(@baseName,@n3 -1)

				-- Defect 14380: if the length of nextName exceeds the maxBaseName
				-- the truncate the baseName instead of the appended text
				set @cpyCodeStr = @cpycode+rtrim(ltrim(cast(@n2 as char)))+')'
				set @len = len(@baseName)+len(@cpyCodeStr)

				if @len > @maxBaseName
				begin
					set @len = @len -@maxBaseName
					set @baseName = left(@baseName,len(@baseName) -@len)
				end

				set @ret_nextName = @baseName+@cpyCodeStr
			end
		end
	end
	
	-- what we do is look & see if your name is unique.
	-- we add (copy n) to it until we find one that works.
	-- you could break this, but noone will in reality
	
	-- handle null else it would end up in infinite loop with @ssql containing null --
	set @ret_nextName = isnull(@ret_nextName,'')
	
	while @cnt1 > 0
	begin       
		set @ssql = 'select  @cnt1 = count('+@nameField+')   from  '+rtrim(ltrim(@tableName))+'  where '+rtrim(ltrim(@nameField))+' =  '''+ rtrim(ltrim(@ret_nextName))+''''
		execute sp_executesql @ssql,N'@cnt1 int output',@cnt1 output
      
		if @cnt1 > 0
		begin
			-- Defect 14380: if the length of nextName exceeds the maxBaseName
			-- the truncate the baseName instead of the appended text 

			set @cpyCodeStr = @cpycode+rtrim(ltrim(cast(@n2 as char)))+')'
			set @len = len(@baseName)+len(@cpyCodeStr)

			if @len > @maxBaseName
			begin
				set @len = @len -@maxBaseName
				set @baseName = left(@baseName,len(@baseName) -@len)
			end

			set @ret_nextName = @baseName+@cpyCodeStr

			set @n2 = @n2+1
		end
	end
	--RETURN @ret_nextName ;
end try
begin catch
	-- Trap error in case wrong query is fired --
	set @errMsg = 'Error_number :: ' + Cast(Error_number() as varchar) +  ' Error_Line :: ' + cast(Error_Line() as varchar) + ' Error_message :: ' + Error_message() 
	execute absp_Util_LogIt @errMsg,1,'absp_GetUniqueName',''
end catch
end


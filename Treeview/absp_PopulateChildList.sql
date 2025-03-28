if exists(select 1 from SYSOBJECTS where ID = OBJECT_ID(N'absp_PopulateChildList') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_PopulateChildList;
end
go

create  procedure absp_PopulateChildList @nodeKey int, @nodeType int

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:	This procedure gets all the child portfolios for the given portfolio
			and populates the data into a temporary table.
Returns:	Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey		^^ Key of the portfolio for which we'll get all parent.
##PD  @nodeType		^^ Portfolio type.
*/

as

begin
	set nocount on;

	declare @sql nvarchar (2000);
	declare @msg varchar(4000);
	declare @me varchar(100);
	declare @curs1 cursor;
	declare @childKey int;
	declare @childType int;

	set @me = 'absp_PopulateChildList';
	set @msg = @me + ' Starting... with ' + str(@nodeKey) + ' and ' + str(@nodeType);
	exec absp_MessageEx @msg;

	begin
		if(@nodeType = 0 or @nodeType = 12)
			set @curs1 = cursor fast_forward for select CHILD_KEY, CHILD_TYPE from FLDRMAP  where FOLDER_KEY = @nodeKey;
		else if(@nodeType = 1)
			set @curs1 = cursor fast_forward for select CHILD_KEY, CHILD_TYPE from APORTMAP where APORT_KEY = @nodeKey;
		else if(@nodeType = 3 or @nodeType = 23)
			set @curs1 = cursor fast_forward for select CHILD_KEY, CHILD_TYPE from RPORTMAP where RPORT_KEY = @nodeKey;
        else
			return;

		--Get the list of all the child nodes--
	     open @curs1
         fetch next from @curs1 into @childKey, @childType
         while @@fetch_status = 0
         begin

         	--Recursively call the procedure to get the child nodes
			execute absp_PopulateChildList @childKey, @childType
			begin transaction;
				insert into #NODELIST values ( @childKey,@childType,@nodeKey,@nodeType);
			commit transaction;
			fetch next from @curs1 into @childKey, @childType
         end
		 close @curs1
         deallocate @curs1
	end
end

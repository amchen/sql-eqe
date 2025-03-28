IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'absp_BuildUse_DropApplicationKeys') AND type in (N'P', N'PC'))
	DROP PROCEDURE absp_BuildUse_DropApplicationKeys
GO

create procedure absp_BuildUse_DropApplicationKeys
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure drops Application Keys (AK) which are foreign keys defined in DICTCNST.

Returns:	None
====================================================================================================
</pre>
</font>
##BD_END
*/
as
begin

	set nocount on

    declare @tn    varchar(100)
    declare @tname varchar(100)
    declare @fname varchar(100)
    declare @qry   varchar(8000)
    declare @list  varchar(8000)
    declare @sql   varchar(8000)

    declare curs1 cursor fast_forward for
		select distinct TableName from DictCnst where CnstType='AK'
		order by TableName

	-- Drop application keys as foreign key constraints
	-- cursor DictCnst by Tablename
	open curs1 fetch next from curs1 into @tname
    while @@FETCH_STATUS = 0
		begin
		print 'Running: exec absp_Util_DropTableConstraint @baseTableName='+''''+@tname+''''+', @cnstType='+'''AK'''
			exec absp_Util_DropTableConstraint @baseTableName=@tname, @cnstType='AK'
			fetch next from curs1 into @tname
		end
    close curs1
    deallocate curs1
end

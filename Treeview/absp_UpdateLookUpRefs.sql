if exists(select * from SYSOBJECTS where ID = object_id(N'absp_UpdateLookupRefs') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_UpdateLookupRefs
end
go
create procedure absp_UpdateLookupRefs  @insertStr varchar(max) out, 
					@tableToUpdate varchar(12),
					@fieldNames varchar(max), 
					@fieldValueTrios varchar(max),
					@whereClause varchar(max),
					@targetDB varchar(130)
as
/*
 ##BD_BEGIN
 <font size ="3">
 <pre style="font-family: Lucida Console;" >
 ====================================================================================================
 DB Version:    MSSQL
 Purpose:       This procedure checks if the sourceDB uses any new lookup. It clones the new lookups records
                in the target database.
 
 Returns:       Nothing.
 
 ====================================================================================================
 </pre>
 </font>
 ##BD_END
 
 ##PD  @targetDB ^^  The database where the data is cloned.
  
 */

begin
set nocount on
 
	declare @sSql nvarchar(max)
	declare @tmpTbl varchar(120)
	declare @replNames varchar(max)
	declare @replaceStr varchar(max)
	declare @tabSep char(2)
	declare @lkupTbl varchar(120)
	declare @lkupFld varchar(120)
	declare @joinTbls varchar(8000)
	declare @joinClause varchar(max)
	declare @countryId char(3)
	declare @cntryBased char(1)
 
	--Exit if same database 
	if @targetDB=''  or @targetDB=DB_NAME()	
	return

	--Enclose within square brackets--
	execute absp_getDBName @targetDB out, @targetDB

	--If targetDB is enclosed within square brackets--  
	if substring(@targetDB,2,len(@targetdb)-2)=DB_NAME()
		return


	--Update Reference for each lookup--
	set @joinTbls = ' mt '
	set @joinClause =' where '
	execute  absp_GenericTableCloneSeparator @tabSep output

	
	declare cursLookup  cursor fast_forward  for 
	select 'D0410','TRANS_ID','' from DICTCOL where TABLENAME= @tableToUpdate and FIELDNAME='TRANS_ID'
	union
	select distinct T1.TABLENAME,T1.EQECOL,T3.CNTRYBASED from DICTTBLX T1,DICTCOL T2, DICTLOOK T3
		   where T1.EQECOL=T2.FIELDNAME and T1.TABLENAME=T3.TABLENAME and T2.TABLENAME= @tableToUpdate and T1.TABLENAME<>'PTL' 
	open cursLookup
	fetch next from cursLookup into  @lkupTbl,@lkupFld,@cntryBased
	while @@fetch_status = 0
	begin   
		set @tmpTbl ='TMP_' + dbo.trim( @lkupTbl)+'_'+dbo.trim(cast (@@SPID as varchar))

		set @replaceStr=REPLACE(' '+@fieldNames + ',',' '+@lkupFld+',',' '+@tmpTbl + '.NEW_VAL'+',')
		set @fieldNames  =SUBSTRING(@replaceStr ,2,LEN(@replaceStr)-2)
		execute absp_StringSetFields @replNames output, @fieldNames, @fieldValueTrios

	    	set @joinTbls=@joinTbls + ','+@tmpTbl  
		set @joinClause =@joinClause + 'mt.' + @lkupFld + ' =' + @tmpTbl +'.OLD_VAL and '

		fetch next from cursLookup into @lkupTbl,@lkupFld,@cntryBased
	end

	close cursLookup
	deallocate cursLookup
	set @insertStr = ' select  distinct '+@replNames+' from  ' + @tableToUpdate + @joinTbls + @joinClause +'  mt.' + @whereClause

end 
    
 
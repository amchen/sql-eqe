if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CopyExposureLookupIDMapRecords') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CopyExposureLookupIDMapRecords
end
go

create procedure absp_CopyExposureLookupIDMapRecords  @sourceExposureKey int, @targetExposureKey int, @targetDB varchar(130) = ''
as 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    ASA
Purpose: This procedure is called when a PPortfolio or Program/RAP is copied.It will create two temp tables
    	 to hold the data for source and target exposureKey. The procedure will then check whether the 
    	 target exposureKey is missing any records that exists for the source exposureKey and copy only those 
    	 records.
  	    
Returns:	Nothing
                   
====================================================================================================
</pre>
</font>
##BD_END

##PD	sourceExposureKey ^^ The exposureKey from where the Policy is copied.
##PD	targetExposureKey ^^ The target exposureKey where the Policy will be copied. 

*/

BEGIN
	declare @sourceDB varchar(130)
	declare @sql varchar(max)
	
	set nocount on
	set @sourceDB = (select DB_NAME())
	
	--Enclose within square brackets--
   	execute absp_getDBName @sourceDB out, @sourceDB
   	
   	--Enclose within square brackets--
   	execute absp_getDBName @targetDB out, @targetDB
	
	-- if the source and target are the same then there is nothing to do 
	if((@sourceDB = @targetDB) and (@sourceExposureKey = @targetExposureKey))
		return
	
	-- Extra check to make sure we have valid source and target ExposureKey 
	if ( @sourceExposureKey <= 0 or @targetExposureKey <= 0)
		return
	
	-- create a temp table to hold all the data for the source ExposureKey
	CREATE TABLE #SRC_EXP_TBL (autoId int NOT NULL IDENTITY (1, 1),
                              ExposureKey int not null, 
                              ID int not null,
                              Name varchar(75) not null,
                              CacheTypeDefID int not null)
                              

	set @sql = 'insert into #SRC_EXP_TBL(ExposureKey,ID,Name, CacheTypeDefID) select distinct ExposureKey,lob1.LineofBusinessID, lob1.Name, CacheTypeDefID ' +
              'from ExposureLookupIDMap e1 inner join ' + @targetDB + '.dbo.LineOfBusiness lob1 on  e1.Name = lob1.Name where CacheTypeDefID = 10 and ExposureKey = ' + rtrim(str(@sourceExposureKey))
              print @sql
	execute(@sql)
	
	set @sql = 'insert into #SRC_EXP_TBL(ExposureKey,ID,Name, CacheTypeDefID) select distinct ExposureKey,t1.TreatyTagID, t1.Name, CacheTypeDefID ' +
              'from ExposureLookupIDMap e1 inner join ' + @targetDB + '.dbo.TreatyTag t1 on  e1.Name = t1.Name where CacheTypeDefID = 22 and ExposureKey = ' + rtrim(str(@sourceExposureKey))
              print @sql
	execute(@sql)
	
	CREATE TABLE #TARGET_EXP_TBL (autoId int NOT NULL IDENTITY (1, 1),
                              ExposureKey int not null, 
                              ID int not null,
                              Name varchar(75) not null,
                              CacheTypeDefID int not null)
                              
	set @sql = 'insert into #TARGET_EXP_TBL(ExposureKey,ID,Name, CacheTypeDefID) '+ 
               'select * from ' + @targetDB + '.dbo.ExposureLookupIDMap where ExposureKey = ' + rtrim(str(@targetExposureKey))
               
	--print @sql
	execute(@sql)
	-- If the target ExposureKey is a new ExposureKey and has no policy associated with
	-- it then we can copy all the records from the source ExposureKey 
	
	if not exists (select top 1 1 from #TARGET_EXP_TBL) 
	begin
		set @sql = 'insert into ' + @targetDB + '.dbo.ExposureLookupIDMap ' + 
                'select ' + rtrim(str(@targetExposureKey)) + ', t1.ID, t1.Name, t1.CacheTypeDefID from #SRC_EXP_TBL t1'
    --print @sql
    execute(@sql)
	end
	else
	begin
		set @sql = 'insert into ' + @targetDB + '.dbo.ExposureLookupIDMap ' +
                'select ' + rtrim(str(@targetExposureKey)) + ', t1.ID, t1.Name, t1.CacheTypeDefID from #SRC_EXP_TBL t1 ' + 
                'left outer join #TARGET_EXP_TBL t2 on t1.ID = t2.ID and t1.Name = t2.Name ' +
                'where t2.id is null '
        execute(@sql)
	end
	
end
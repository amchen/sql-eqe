if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetCustomLookups') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_GetCustomLookups
end
go


create procedure absp_GetCustomLookups @path varchar(1000)
as
begin

   set nocount on
   
   declare @fileName varchar(1000)  
   declare @tablename varchar(100)
   declare @sql nvarchar(max)
   declare @cnt int
   declare @IsUserLkupSchema  int
     
   set @IsUserLkupSchema=0
   
   --Create unload path--
   exec absp_Util_CreateFolder 'C:\TMP'
   exec absp_Util_CreateFolder 'C:\TMP\Lookup Information'
   
   --if LOOKUP_COUNT table exists then drop table--
   if exists( select 1 from SYS.TABLES where NAME='LOOKUP_COUNT')
   		drop table LOOKUP_COUNT	
   		
   --Create and load LOOKUP_COUNT table
   create table LOOKUP_COUNT 
   (
      TABLE_NAME varchar(100), 
      EXPECTED_COUNT int, 
      ACTUAL_COUNT  int
   ) 
   
   set @fileName=dbo.trim(@path) + '\LOOKUP_COUNT.txt'  
   exec absp_Util_LoadData 'LOOKUP_COUNT',@fileName, '|'
   
   
   --Check if D0410 has any User Lookup schema--
   if exists(select 1 from D0410 where TRANS_ID not in(0,10000,57,58,59))
   begin
   		set @IsUserLkupSchema=1
   		if exists( select 1 from SYS.TABLES where NAME='USER_LOOKUP_INFO')
   			drop table USER_LOOKUP_INFO
   
    	create table USER_LOOKUP_INFO 
   		(
   		TABLE_NAME varchar(100),
   		NUM_USER_LOOKUPS int, 
   		TRANS_ID int
   		)
   	
   		--Unload D0410 table--
  		exec absp_Util_UnloadData 'T','D0410','C:\TMP\Lookup Information\D0410.txt'  	
   	end

    
    --If we have any custom lookups in system range unload the lookup table
    --If we have lookups under user Lookup schema, add the details in USER_LOOKUP_INFO 
    --STATEL does not have TRANS_ID column
    
   declare curs1 cursor for 
   	  select TABLENAME from DICTTBLX where TYPE NOT in ('A' , 'P') and TABLENAME<>'STATEL'
   open curs1
   fetch curs1 into @tableName
   while @@fetch_status =0
   begin
      --Get rowcount for system transId--
      set @sql='select @cnt = COUNT(*)  from ' + dbo.trim(@tableName ) + ' where TRANS_ID in (0,10000,57,58,59)'
      execute absp_MessageEx @sql
      execute sp_executesql @sql,N'@cnt int output',@cnt output
      
      --Update ACTUAL_COUNT--
   	  set @sql = 'update  LOOKUP_COUNT set  ACTUAL_COUNT = ' + str(@cnt) + ' where TABLE_NAME = '''+ dbo.trim(@tableName ) + ''''
   	  execute absp_MessageEx @sql
   	  execute(@sql)
   	  
   	  if exists (select 1 from LOOKUP_COUNT where TABLE_NAME = @tableName and EXPECTED_COUNT <>  @cnt )
   	  begin
   	  	 set @fileName='C:\TMP\Lookup Information\' +dbo.trim(@tableName ) +'.txt'
   	  	 exec absp_Util_UnloadData 'T', @tableName  ,@fileName
   	  end
   	  
   	  if @IsUserLkupSchema=1
   	  begin
   	  	   set @sql='insert into USER_LOOKUP_INFO
   	  	              select ''' + dbo.trim(@tableName) + ''','+ str(COUNT(*)) + ',T1.TRANS_ID from D0410 T1, ' + dbo.trim(@tableName) +' T2 where 
   	  	   			T1.TRANS_ID=T2.TRANS_ID and
   	  	   			T1.TRANS_ID not in (0,10000,57,58,59)
   	  	   			GROUP BY T1.TRANS_ID'
   	       execute absp_MessageEx @sql 	  	   
   	  	   execute(@sql)
   	  end
   	  
   	  fetch curs1 into @tableName
   end
   close curs1
   deallocate curs1
   
   --Unload LOOKUP_COUNT table--
   exec absp_Util_UnloadData 'T','LOOKUP_COUNT','C:\TMP\Lookup Information\LOOKUP_COUNT.txt'
   
   
   if exists(select 1 from SYS.TABLES where NAME = 'USER_LOOKUP_INFO')
   begin
   		exec absp_Util_UnloadData 'T','USER_LOOKUP_INFO','C:\TMP\Lookup Information\USER_LOOKUP_INFO.txt'
   end

   
end




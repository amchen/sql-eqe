if exists(select * from SYSOBJECTS where ID = object_id(N'absp_createATSCFolder') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_createATSCFolder
end
go

create procedure absp_createATSCFolder
as
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure creates a Folder named ATSC_FOLDER under WCe. It is used during 
     Scalability testing to keep the Cloned Big Portfolio nodes.The WCe folder is 
     also created if it does not exist.


Returns: Nothing.

====================================================================================================
</pre>
</font>
##BD_END 

*/
begin

/* This procedure creates a Folder named ATSC_FOLDER under WCe. It will be used for Scalability testing 
   to store the cloned nodes.*/


   set nocount on
   
            declare @fldrKey int
            declare @pprtKey int
            declare @dt varchar(15)
            
            --Do nothing if ATSC_FOLDER exists
            if not exists(select 1 from FLDRINFO where LONGNAME='ATSC_FOLDER') 
            begin
		 exec absp_Util_GetDateString @dt output,'yyyymmddhhnnss'

		 --Check if WCe folder exists --
                 --If not create it
		 if not exists(select 1 from FLDRINFO where LONGNAME='.Root')
		 begin
			set identity_insert FLDRINFO on
			insert into FLDRINFO (FOLDER_KEY,LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,CURR_NODE,CURRSK_KEY)values(1,'.Root','ACTIVE',@dt,1,1,'Y',1);            
			set identity_insert FLDRINFO off
			
			--Create map entry for WCe
		        if not exists(select 1 from fldrmap where FOLDER_KEY = 0 and CHILD_KEY= 1 )
			begin
				insert into FLDRMAP (FOLDER_KEY,CHILD_KEY,CHILD_TYPE)values(0,1,0)
			end 
			print 'WCe Folder created' 
		  end
		  else
		  begin
			print 'WCe Folder exists' 
                  end;
                  --Create ATSC_FOLDER and its map entry with WCe
                  insert into FLDRINFO (LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,CURR_NODE,CURRSK_KEY)values('ATSC_FOLDER','ACTIVE',@dt,1,1,'N',0)
                  select  @fldrKey=max(FOLDER_KEY)  from FLDRINFO
                  insert into FLDRMAP (FOLDER_KEY,CHILD_KEY,CHILD_TYPE)values(1,@fldrKey,0)
                  print 'Created ATSC_FOLDER and its map entry' 

		  --Create ATSC_PPORT and its map entry with ATSC_FOLDER
                  insert into PPRTINFO (LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY) values('ATSC_PPRT','ACTIVE',@dt,1,1);
                  select  @pprtKey = max(PPORT_KEY)  from PPRTINFO;
                  insert into FLDRMAP (FOLDER_KEY,CHILD_KEY,CHILD_TYPE)values(@fldrKey,@pprtKey,2);  
                  print 'Created ATSC_PPRT and its map entry'
            end 
            else
            begin
            	print 'ATSC_FOLDER exists' 
            end
end

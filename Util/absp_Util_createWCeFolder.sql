if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_createWCeFolder') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_createWCeFolder
end
go

create procedure absp_Util_createWCeFolder @folderName char(120)='.Root'
as

/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    ASA
Purpose:

     This procedure creates a Folder named .Root if it does not already exist or a 
	 FOLDER_KEY = 1 does not already exist.
    
    	    
Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END 
             
*/
begin

	set nocount on

	declare @dt varchar(15)
	declare @newFldrKey int
	declare @msg varchar(100)
	
	set @newFldrKey = 0
	exec absp_MessageEx 'absp_Util_createWCeFolder'

	--Check if WCe folder exists --
	--If not create it
	if not exists(select 1 from FLDRINFO where LONGNAME = rtrim(ltrim((@folderName)) ))
	begin
		exec absp_Util_GetDateString @dt output,'yyyymmddhhnnss'

		
		insert into FLDRINFO (LONGNAME,STATUS,CREATE_DAT,CREATE_BY,GROUP_KEY,CURR_NODE,CURRSK_KEY)
		values(rtrim(ltrim(@folderName)),'ACTIVE',@dt,1,1,'Y',1)            
		
		set @newFldrKey = @@identity
		
		--Create map entry for WCe
		insert into FLDRMAP (FOLDER_KEY,CHILD_KEY,CHILD_TYPE)values(0,@newFldrKey,0)
		set @msg = 'Folder ' + rtrim(ltrim(@folderName)) + ' created.'
		exec absp_MessageEx @msg 
	end

	else
	begin
		set @msg = 'Folder ' + rtrim(ltrim(@folderName)) + ' exists.'
		exec absp_MessageEx @msg 
	end

end
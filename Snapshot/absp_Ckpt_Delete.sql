if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Ckpt_Delete') and objectproperty(ID,N'isprocedure') = 1)
begin
	drop procedure absp_Ckpt_Delete
end
go

create procedure absp_Ckpt_Delete @ckptKey int ,@ckptAll char(1) = 'N' ,@raiseErrorOnFail int = 0 

/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This function deletes records from CKPTINFO and also drops  snapshot tables
based on ckptKey and the ckptAll flag.


Returns:  Returns 0 on success, non-zero if failed
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @ckptKey           ^^ An integer value which signifies which Final Results are to be deleted.
##PD  @ckptAll           ^^ Used to guard against accidental deletion of ALL snapshot.
##PD  @raiseErrorOnFail  ^^ Description related to the Checkpoint(unused parameter).

##RD @retCode ^^ An integer value 0 on success, non-zero on failure.
*/
as

begin

   set nocount on
   
	/*
	This proc deletes a Final Results snapshot based on ckptKey.

	ckptKey  Specifies which Final Results are to be deleted.
	This parameter has the following use:

	ckptKey < 0    Keep only the most recent n ckptKey snapshots
	(-3 means keep the last 3 snapshot, delete all others)
	ckptKey = 0    Delete ALL snapshots, requires ckptAll = Y
	ckptKey > 0    Delete the matching snapshot for ckptKey

	ckptAll  Used to guard against accidental deletion of ALL snapshot

	Returns 0 on success, non-zero if failed
	*/
	declare @retCode int
	declare @ckptKeyStr char(20)
	declare @cnt int
	declare @offset int
	declare @sql varchar(255)
	declare @curs_TN varchar(255)
	declare @curs_CK int
	declare @curs_TN_1 varchar(255)
   
	execute absp_MessageEx 'absp_Ckpt_Delete - Started'
	set @retCode = 0
	if not exists(select  1 from SYS.TABLES where NAME = 'CKPTINFO')
	begin
		set @retCode = 1
		execute absp_Migr_RaiseError 1,'Table CKPTINFO does not exist.'
	end
   	else
   	begin
    		-- delete specific ckptKey snapshot
    
    		-- end of the cursor
    		-- keep n recent ckptKey snapshots, delete ALL others recursively
     		-- end of the cursor
      		-- delete ALL snapshots, requires ckptKey = 0 and ckptAll = Y
       		-- end of the cursor
      		if(@ckptKey > 0)
      		begin
			set @ckptKeyStr = rtrim(ltrim(cast(@ckptKey as char)))
			set @sql = 'delete CKPTINFO where CKPT_KEY = '+@ckptKeyStr
			execute absp_MessageEx @sql
			--execute(@sql)
			delete CKPTINFO where CKPT_KEY = @ckptKeyStr
			declare curs_name  cursor fast_forward for select  rtrim(ltrim(NAME)) as TN from SYS.TABLES where
			NAME like '%_CKPT_'+@ckptKeyStr
			open curs_name
			fetch next from curs_name into @curs_TN
			while @@fetch_status = 0
			begin
				set @sql = 'drop table '+@curs_TN
				execute absp_MessageEx @sql
				execute(@sql)
				fetch next from curs_name into @curs_TN
			end
			close curs_name
			deallocate curs_name
		end
      		else
      		begin
	 		if(@ckptKey < 0)
	 		begin
				set @offset = 0
				set @cnt = @ckptKey
				declare curs_ckpt_key  cursor fast_forward for select  CKPT_KEY as CK from CKPTINFO order by CREATE_DAT desc
				open curs_ckpt_key
				fetch next from curs_ckpt_key into @curs_CK
				while @@fetch_status = 0
				begin
					if(@cnt = 0)
					begin
						execute absp_Ckpt_Delete @curs_CK,@ckptAll,@raiseErrorOnFail
						set @offset = @offset+1
					end
		   			else
					begin
						set @cnt = @cnt+1
					end
		   			fetch next from curs_ckpt_key into @curs_CK
				end
				close curs_ckpt_key
				deallocate curs_ckpt_key
	  		end
	  		else
	  		begin
	  			if(@ckptAll = 'Y')
	  			begin
					truncate table CKPTINFO
					declare curs_name_1  cursor fast_forward for select  rtrim(ltrim(NAME)) as TN from SYS.TABLES where(NAME like '[APR]0%_CKPT_[0-9]%' or
					NAME like 'SP_FILES_CKPT_[0-9]%' or
					NAME like '%DONE_CKPT_[0-9]%')
					open curs_name_1
					fetch next from curs_name_1 into @curs_TN_1
					while @@fetch_status = 0
					begin
		        			set @sql = 'drop table '+@curs_TN_1
						execute absp_MessageEx @sql
						execute(@sql)
						fetch next from curs_name_1 into @curs_TN_1
					end
					close curs_name_1
					deallocate curs_name_1
	   			end
	 		end
      		end
   	end
   	execute absp_MessageEx 'absp_Ckpt_Delete - Done'
	return @retCode
end
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Ckpt_Create') and objectproperty(ID,N'isprocedure') = 1)
begin
	drop procedure absp_Ckpt_Create
end
go

create procedure absp_Ckpt_Create @ckptName char(50),@ckptUser char(25),@ckptDescript char(254),@ckptType int,@createEmptyTbls int = 1,@raiseErrorOnFail int = 0 
 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure inserts records into CKPTINFO and also creates duplicate tables 
with or without data for existing tables(all APORT, RPORT, PPORT, POLICY, SITE
and MISC related tables which has to be checkpointed during migration) depending
on the ckptType and createEmptyTbls flag.


Returns:       nothing

=================================================================================
</pre>
</font>
##BD_END

##PD  @ckptName           ^^ name of the Checkpoint.
##PD  @ckptUser           ^^ Name of the user who created this Checkpoint.
##PD  @ckptDescript       ^^ Description related to the Checkpoint.
##PD  @ckptType           ^^ An integer value for the Checkpoint type.
##PD  @createEmptyTbls    ^^ An integer value which signifies whether the new table that is created should hold data or not.
##PD  @raiseErrorOnFail   ^^ A flag value to raise error(Unused parameter).


*/
as

begin

   set nocount on
   
  /*
	This proc creates a Final Results snapshot based on ckptType.

	ckptType specifies which Final Results are to be saved. This parameter is an ORed combination of flags
	from the following groups of flags and values.

	1      CKPT_APORT
	2      CKPT_RPORT
	4      CKPT_PPORT
	8      CKPT_POLICY
	16     CKPT_SITE
	32     CKPT_MISC

	The tables that are snapshot are found in CKPTCTRL.
	*/
	declare @CKPT_APORT int
	declare @CKPT_RPORT int
	declare @CKPT_PPORT int
	declare @CKPT_POLICY int
	declare @CKPT_SITE int
	declare @CKPT_MISC int
	declare @postfix char(50)
	declare @ckptKey int
	declare @ckptKeyStr char(20)	
	declare @CrtTblMsg varchar(255)
	declare @curs_TN_1 char(120)
	declare @curs_TN_3 char(120)
	declare @curs_TN_2 CHAR(120)
	declare @curs_TN_8 char(120)
	declare @curs_TN_9 char(120)
	declare @curs_TN_32 char(120)
	declare @createDt char(20)
	
	-- start
	execute absp_MessageEx 'absp_Ckpt_Create - Started'
	-- set constants
	set @CKPT_APORT = 1
	set @CKPT_RPORT = 2
	set @CKPT_PPORT = 4
	set @CKPT_POLICY = 8
	set @CKPT_SITE = 16
	set @CKPT_MISC = 32
	
	-- init variables
	set @ckptKey = 0
	set @ckptKeyStr = ''
	if not exists(select  1 from SYS.OBJECTS where NAME = 'CKPTCTRL')
	begin
		execute absp_Migr_RaiseError 1,'Table CKPTCTRL does not exist.'
	end
	-- end of the cursor
	if not exists(select  1 from  SYS.OBJECTS where NAME = 'CKPTINFO')
	begin
		execute absp_Migr_RaiseError 1,'Table CKPTINFO does not exist.'
	end
	else
	begin
		if(@ckptType > 0)
		begin
			-- create CKPTINFO record
			exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
			insert into CKPTINFO(CKPT_NAME,CREATE_DAT,USER_NAME,DESCRIPT) values(@ckptName,@createDt,@ckptUser,@ckptDescript)
			set @ckptKey = @@identity
			set @ckptKeyStr = rtrim(ltrim(cast(@ckptKey as char)))
			set @postfix = '_CKPT_'+@ckptKeyStr
			-- APORT snapshot
		   
			declare curs_tablename_nodetype_1  cursor fast_forward for select distinct rtrim(ltrim(TABLE_NAME)) from CKPTCTRL where
			NODE_TYPE in(1) and FOR_MIGR = 'Y'
			
			open curs_tablename_nodetype_1
			fetch next from curs_tablename_nodetype_1 into @curs_TN_1
			while @@FETCH_STATUS = 0
			begin
				if(@ckptType & @CKPT_APORT > 0)
				begin
					execute absp_Ckpt_Table @curs_TN_1,@postfix
				end
				else
				begin
					if(@createEmptyTbls > 0)
					begin
						set @CrtTblMsg = ltrim(rtrim(@curs_TN_1)) + @postfix
						execute absp_Migr_CreateTable @curs_TN_1,@CrtTblMsg,0
					end
				end
				fetch next from curs_tablename_nodetype_1 into @curs_TN_1
			end
			close curs_tablename_nodetype_1
			deallocate curs_tablename_nodetype_1
			-- end of the cursor
	
			-- RPORT snapshot

			declare curs_tablename_nodetype_3  cursor fast_forward for select distinct rtrim(ltrim(TABLE_NAME)) from CKPTCTRL where
			NODE_TYPE in(3,7) and FOR_MIGR = 'Y'

			open curs_tablename_nodetype_3

			fetch next from curs_tablename_nodetype_3 into @curs_TN_3
			while @@FETCH_STATUS = 0
			begin
				if(@ckptType & @CKPT_RPORT > 0)
				begin
					execute absp_Ckpt_Table @curs_TN_3,@postfix
				end
				else
				begin
					if(@createEmptyTbls > 0)
					begin
						set @CrtTblMsg = ltrim(rtrim(@curs_TN_3)) + @postfix
						execute absp_Migr_CreateTable @curs_TN_3,@CrtTblMsg,0
					end
				end
				fetch next from curs_tablename_nodetype_3 into @curs_TN_3
			end
			close curs_tablename_nodetype_3
			deallocate curs_tablename_nodetype_3
			-- end of the cursor
	 
			-- PPORT snapshot

			declare curs_tablename_nodetype_2  cursor fast_forward for select distinct rtrim(ltrim(TABLE_NAME)) from CKPTCTRL where
			NODE_TYPE in(2) and FOR_MIGR = 'Y'

			open curs_tablename_nodetype_2

			fetch next from curs_tablename_nodetype_2 into @curs_TN_2
			while @@FETCH_STATUS = 0
			begin
				if(@ckptType & @CKPT_PPORT > 0)
				begin
					execute absp_Ckpt_Table @curs_TN_2,@postfix
				end
				else
				begin
					if(@createEmptyTbls > 0)
					begin
						set @CrtTblMsg = ltrim(rtrim(@curs_TN_2)) + @postfix
						execute absp_Migr_CreateTable @curs_TN_2,@CrtTblMsg,0
					end
				end
				fetch next from curs_tablename_nodetype_2 into @curs_TN_2
			end
			close curs_tablename_nodetype_2
			deallocate curs_tablename_nodetype_2

			-- end of the cursor
	  
			-- POLICY snapshot

			declare curs_tablename_nodetype_8  cursor fast_forward for select distinct rtrim(ltrim(TABLE_NAME)) from CKPTCTRL where
			NODE_TYPE in(8) and FOR_MIGR = 'Y'

			open curs_tablename_nodetype_8

			fetch next from curs_tablename_nodetype_8 into @curs_TN_8
			while @@FETCH_STATUS = 0
			begin
				if(@ckptType & @CKPT_POLICY > 0)
				begin
					execute absp_Ckpt_Table @curs_TN_8,@postfix
				end
				else
				begin
					if(@createEmptyTbls > 0)
				   	begin
						set @CrtTblMsg = ltrim(rtrim(@curs_TN_8))+@postfix
						execute absp_Migr_CreateTable @curs_TN_8,@CrtTblMsg,0
				   	end
				end
				fetch next from curs_tablename_nodetype_8 into @curs_TN_8
			end
			close curs_tablename_nodetype_8
			deallocate curs_tablename_nodetype_8
			-- end of the cursor

			-- SITE snapshot
	   
			declare curs_tablename_nodetype_9  cursor fast_forward for select distinct rtrim(ltrim(TABLE_NAME)) from CKPTCTRL where
			NODE_TYPE in(9) and FOR_MIGR = 'Y'
   	   
	   		open curs_tablename_nodetype_9
	   
	   		fetch next from curs_tablename_nodetype_9 into @curs_TN_9
	   		while @@FETCH_STATUS = 0
	   		begin
				if(@ckptType & @CKPT_SITE > 0)
				begin
		   			execute absp_Ckpt_Table @curs_TN_9,@postfix
				end
	        		else
				begin
		   			if(@createEmptyTbls > 0)
		   			begin
						set @CrtTblMsg = ltrim(rtrim(@curs_TN_9))+@postfix
						execute absp_Migr_CreateTable @curs_TN_9,@CrtTblMsg,0
		   			end
	        		end
				fetch next from curs_tablename_nodetype_9 into @curs_TN_9
	     		end
	     		close curs_tablename_nodetype_9
	     		deallocate curs_tablename_nodetype_9
	  		-- end of the cursor
	  
	  		-- MISC snapshot
	 		declare curs_tablename_nodetype_32  cursor fast_forward for select distinct rtrim(ltrim(TABLE_NAME)) from CKPTCTRL where
   	 		NODE_TYPE in(32) and FOR_MIGR = 'Y'
   	 
	 		open curs_tablename_nodetype_32
	 
			fetch next from curs_tablename_nodetype_32 into @curs_TN_32
	 		while @@FETCH_STATUS = 0
	 		begin
				if(@ckptType & @CKPT_MISC > 0)
				begin
					execute absp_Ckpt_Table @curs_TN_32,@postfix
				end
				else
				begin
					if(@createEmptyTbls > 0)
					begin
						set @CrtTblMsg = ltrim(rtrim(@curs_TN_32))+@postfix
						execute absp_Migr_CreateTable @curs_TN_32,@CrtTblMsg,0
					end
				end
				fetch next from curs_tablename_nodetype_32 into @curs_TN_32
	  		end
	  		close curs_tablename_nodetype_32
	  		deallocate curs_tablename_nodetype_32
        	end
   	end
	execute absp_MessageEx 'absp_Ckpt_Create - Done'
end
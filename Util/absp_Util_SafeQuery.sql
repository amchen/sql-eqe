if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_SafeQuery') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_SafeQuery
end
go

create procedure absp_Util_SafeQuery @sql varchar(max),@display INT = 0, @execInChunks INT = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:       	This procedure executes a SQL statement and catches an exception for deadlocks or insertions
				of duplicate keys. For any other exception a system generated error is displayed. 

Returns:       	Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  @sql ^^ The SQL statement that is to be tested.
##PD  @display ^^ A flag which indicates if a message is to be recorded in the log.

*/
as
begin
 
   set nocount on
   
 /*
  SDG__00011956 -- do not fail if alreadyExistsException or deadLockException
  This procedure will execute query that may fail.   It will ignore the failure.
  Optinally it can show a message when the failure occcurs.

  */
   	declare @msgText 		varchar(255)
   	declare @error_number 	int
	begin try
		 
		  set xact_abort off 	-- only the Transact-SQL statement that raised the error is rolled back 
								-- and the transaction continues processing. 
								-- Depending upon the severity of the error, 
								-- the entire transaction may be rolled back even when SET XACT_ABORT is OFF.
		  if @execInChunks != 0
		  begin
			execute dbo.absp_Util_ExecSqlInChunks @sql
		  end
		  else 
		  begin
			execute(@sql)
		  end
		  set xact_abort on		-- if a Transact-SQL statement raises a run-time error, 
								-- the entire transaction is terminated and rolled back
		  return
	end try
		
	begin catch
		select @error_number = error_number()
		if (XACT_STATE()) = -1
		begin
			print 
				N'The transaction is in an uncommittable state. ' +
				'Rolling back transaction.'
			rollback transaction
		end

		-- Test whether the transaction is active and valid.
		if (XACT_STATE()) = 1
		begin
			print
				N'The transaction is committable. ' +
				'Committing transaction.'
			commit transaction   
		end
		
		if @display > 0
		begin
			if @error_number  = 2714 
				begin
					set @msgText = 'Ignoring Object already Exists Error for " ' + @sql  + ' "'
					exec absp_messageEx @msgText
				end
			else	
				begin
					if @error_number  = 1205
						begin
							set @msgText = 'Ignoring Deadlock Error for " ' + @sql  + ' "'
							exec absp_messageEx @msgText
						end
					else
						begin
							set @msgText = 'Caught another type of Error for " ' + @sql  + ' "'
							exec absp_messageEx @msgText
						end
				end
		end
		
		set xact_abort on		-- if a Transact-SQL statement raises a run-time error, 
								-- the entire transaction is terminated and rolled back

		return
	end catch
end

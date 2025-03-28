IF  EXISTS(SELECT * FROM SYSOBJECTS WHERE id = object_id(N'absp_Util_CopyCustRegInfo') and objectproperty(ID,N'IsProcedure') = 1)
BEGIN
   DROP PROCEDURE absp_Util_CopyCustRegInfo
END

GO


CREATE PROCEDURE [dbo].[absp_Util_CopyCustRegInfo]
	@rc varchar(255) output,
	@sourceDb varchar(255),
	@destDb varchar(255)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure attaches a database file located in $\WceDB\_CurrencyDB
Returns:       Successful or Error messages
====================================================================================================
</pre>
</font>
##BD_END

##PD  @sourceDb ^^ copy Custom Region data etc. from this database
##PD  @destDb ^^  to this database
##RD  @rc ^^ successful or error messages.
*/

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @cmd varchar(1000)
	DECLARE @status int
	DECLARE @tableName varchar(255)
	
	SET @rc = ''
	SET @status = 0
	
	BEGIN TRY
		BEGIN TRANSACTION
			----- Copy table CUST_RGN
			SET @tableName = 'CUST_RGN'
			SET @cmd = 'drop table [' + @destDb + '].dbo.' + @tableName
			SET @cmd = @cmd + '; SELECT * INTO [' + @destDb + '].dbo.' + @tableName + ' FROM [' + @sourceDb + '].dbo.' + @tableName
			EXEC (@cmd)			
		COMMIT
	END TRY
	
	BEGIN CATCH
		ROLLBACK
		SET @rc = 'Error in copying Custom Region Data from ' + @sourceDb + 'to ' + @destDb + ': '+ ERROR_MESSAGE()
		SET @status = -1
	END CATCH
	
	RETURN @status
END

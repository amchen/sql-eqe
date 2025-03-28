if exists(select * from SYSOBJECTS where ID = object_id(N'absp_MarkReportAsAvailableForFailedImport') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MarkReportAsAvailableForFailedImport;
end
go

create procedure absp_MarkReportAsAvailableForFailedImport
	@engineCallID int,
	@nodeKey int,
	@nodeType int,
	@exposureKey int=0,
	@accountKey int=0,
	@anlCfgKey int=0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:	The procedure updates the Status column of AvailableReport table to 'Available'
		based on the given nodeKey and nodeType

Returns:	Nothing
====================================================================================================
</pre>
</font>

##PD  @engineCallID  ^^ The flag for messaging purpose only.
##PD  @nodeKey  ^^ The nodeKey of the selected node.
##PD  @nodeType  ^^ The nodeType of the selected node.
##PD  @exposureKey  ^^ The exposure Key ( in case of Exposure and Analysis).
##PD  @accountKey  ^^ The account Key ( in case of Analysis).
##PD  @anlCfgKey  ^^ The anlCfg Key for which the status is to be updates.

##BD_END
*/
as
begin try
	set nocount on;

	exec absp_MarkReportAsAvailable @engineCallID,@nodeKey,@nodeType,@exposureKey,@accountKey,@anlCfgKey 
	
	select ''
			
end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch

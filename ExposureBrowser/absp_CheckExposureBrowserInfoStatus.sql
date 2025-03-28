if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CheckExposureBrowserInfoStatus') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_CheckExposureBrowserInfoStatus
end
go

create  procedure absp_CheckExposureBrowserInfoStatus @BrowserDataStatus varchar(50) out, @nodeKey int=-1,@nodeType int =-1,@exposureKey int=-1

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose: The procedure returns the status of ExposureBrowser data.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey  ^^ The node key for which the browser  information status is to be determined.
##PD  @nodeType  ^^ The node type for which the browser  information status is to be determined.
##PD  @exposureKey  ^^ The exposureKey for which the browser  information status is to be determined.
*/
as
begin
	set nocount on
	declare @dbName varchar(200)

	set @dbName=DB_NAME()
	create table #TMP (ExposureKey int)
	if @exposureKey=-1
		insert into #TMP select ExposureKey from ExposureMap where ParentKey= @nodeKey and ParentType=@nodeType;
	else
		insert into #TMP select @exposureKey

	if exists(select 1 from ExposureInfo A inner join #TMP B on  A.ExposureKey=B.ExposureKey and A.isbrowserdatagenerated='N' and A.Status='Imported')
	begin
		if exists(select 1 from BatchJob where dbName=@dbName and JobTypeID = 24 and ((NodeType=2 and @nodeType = 2 and PportKey=@nodeKey)
														or(nodeType=7 and @nodeType = 7 and  ProgramKey=@nodeKey)
														or(nodeType=27 and @nodeType = 27 and  ProgramKey=@nodeKey)
														or(@nodeType=-1 and @nodeKey=-1 and ExposureKey=@exposureKey)
														) and Status='R' )

			set @BrowserDataStatus='In Progress'
		else
			set @BrowserDataStatus='No Data'
	end
	else
		set @BrowserDataStatus='Available'

end
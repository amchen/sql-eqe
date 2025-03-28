if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_IsPasteLinked') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_IsPasteLinked
end
go

create procedure absp_Util_IsPasteLinked @nodeKey int, @nodeType int
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:    This procedure checks if the current node is paste-linked
Returns:    0 or 1
Example:    exec absp_Util_IsPasteLinked 1, 2
====================================================================================================
</pre>
	</font>
##BD_END

##PD  @NodeKey   ^^  The node type for the requested report.
##PD  @NodeType  ^^  The node key for the requested report.

*/

begin try

	declare @i int, @cnt int
	declare @fldrLinkCount int
	declare @aportLinkCount int
	declare @rportLinkCount int
	declare @pasteLinkCount int

	--when deleting an exposureset an exposureKey will be sent from Java.
	set @fldrLinkCount=0
	set @aportLinkCount=0
	set @rportLinkCount=0
	set @pasteLinkCount=0

	if @nodeType = 2 or @nodeType = 23
	begin
		--Check for an Aport PasteLink
		select @fldrLinkCount=COUNT(*) from FLDRMAP where Child_Key=@nodeKey AND Child_Type=@nodeType;
		--Check for an Aport PasteLink
		select @aportLinkCount=COUNT(*) from APORTMAP where Child_Key=@nodeKey AND Child_Type=@nodeType;
	end	
	if @nodeType = 27
	begin
		select @rportLinkCount=COUNT(*) from RPORTMAP where Child_Key=@nodeKey AND Child_Type=@nodeType;
	end

	set @pasteLinkCount = @fldrLinkCount + @aportLinkCount + @rportLinkCount 
	
	-- if count = 1, the node is not paste-linked								
    if @pasteLinkCount = 1 
		return 0
	else	
		return 1
end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch
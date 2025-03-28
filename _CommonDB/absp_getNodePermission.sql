if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_getNodePermission') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_getNodePermission;
end
go

create procedure absp_getNodePermission
	@userKey int,
	@nodeCreatedBy varchar(50),
	@nodeGroupName varchar(50) = ''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure will return the permission set to show, read, write, delete, analyze, attach, 
			and detach a node given the user_key, the creator name and/or group name of the node
Returns:	Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @userKey ^^ the user key who tries to access the node
##PD  @nodeCreatedBy ^^ The user name who created the node
##PD  @nodeGroupName ^^ The group name of the group who created the node
*/

as

begin
	 set nocount on; 
	 declare @userGroupKey int
	 declare @groupName varchar(50) 
	 declare @groupRight int

	 set @groupRight = 0
	 
	 -- get the user main group key
	 select @userGroupKey = group_key from userinfo where user_key = @userKey
	 
	 if len(@nodeGroupName) = 0 select @nodeGroupName= group_name from usergrps inner join userinfo on usergrps.group_key = userinfo.group_key where user_name = rtrim(@nodeCreatedBy)
		
	 -- get the right to see the node by see if one of the user group keys match the node group key
	 select @groupRight = 1 from usrgpmem join usergrps on usrgpmem.group_key = usergrps.group_key where user_key = @userKey and group_name = rtrim(@nodeGroupName)
	 --select @userGroupKey, @groupRight
	 
	 -- if the user main group key is admin, give all the rights
	 if	@userGroupKey = 1
		select show=1, canRead=1, write=1, remove=1, analyze=1, canAttach=1, detach=1
	 else
	 begin
	 	-- if the user main group is the same as the node group name, set the IN-GROUP permission
		if exists(select 1 from usergrps where group_key = @userGroupKey and group_name = rtrim(@nodeGroupName))
			select @groupRight show, 
				case grp_read when 'Y' then 1 else 0 end canRead, 
				case grp_write when 'Y' then 1 else 0 end write, 
				case grp_dlete when 'Y' then 1 else 0 end remove, 
				case grp_analz when 'Y' then 1 else 0 end analyze, 
				case grp_atach when 'Y' then 1 else 0 end canAttach, 
				case grp_dtach when 'Y' then 1 else 0 end detach 
			from usergrps where group_key = @userGroupKey
		else
		-- if the user main group is NOT the same as the node group name, set the OTHER-GROUP permission
			select @groupRight show, 
				case othr_read when 'Y' then 1 else 0 end canRead, 
				case othr_write when 'Y' then 1 else 0 end write, 
				case othr_dlete when 'Y' then 1 else 0 end remove, 
				case othr_analz when 'Y' then 1 else 0 end analyze,
				case othr_atach when 'Y' then 1 else 0 end canAttach, 
				case othr_dtach when 'Y' then 1 else 0 end detach 
			from usergrps where group_name = rtrim(@nodeGroupName)	
	 end
 end
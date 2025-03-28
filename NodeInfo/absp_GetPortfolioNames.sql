if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetPortfolioNames') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_GetPortfolioNames
end

go

create procedure absp_GetPortfolioNames @parentNodeKey int ,@userKey int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return multiple (4) result sets, which contain information of all child nodes
underneath an accumulation portfolio, sorted by child node names.

Returns:       Multiple result sets, each result set contains:

1. Child Key
2. Child Type
3. Name of the Child
4. Group key for the current user
5. Extra Key
6. Count
7. Attrib
====================================================================================================
</pre>
</font>
##BD_END

##PD  @parentNodeKey ^^  The key for the accumulation portfolio to have its child nodes list fetched.
##PD  @userKey ^^  The USER_KEY of the current user. The USER_KEY will determine rights, and rights determine what is actually returned.

##RS  CHILD_KEY ^^  The key of the child node returned.
##RS  CHILD_TYPE ^^  The type of the child node.
##RS  LONGNAME ^^  The name of the child node.
##RS  GROUP_KEY ^^  The key of the Group the user belongs to. This determines if the user can see all groups, if the user is admin, he can see all groups.
##RS  EXTRA_KEY ^^  Always -1.
##RS  CNT ^^  Count or Number of the children being returned.
##RS  ATTRIB ^^  Attribute value.


*/
begin

   set nocount on
   
   execute absp_TreeviewGetAPortNodesList @parentNodeKey,@userKey
end



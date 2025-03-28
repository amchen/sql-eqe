if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewGetAPortNodesList') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewGetAPortNodesList
end
 go

create procedure absp_TreeviewGetAPortNodesList @parentNodeKey int ,@userKey int 

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
as

begin
   set nocount on
   declare @adminUser int
   declare @sql nvarchar(4000)
  -- are you an admin user"?"
   set @sql = 'select  @adminUser = count(USRGPMEM.GROUP_KEY) from USRGPMEM join USERGRPS on
   USRGPMEM.GROUP_KEY = USERGRPS.GROUP_KEY where USERGRPS.GROUP_KEY = 1 and
   USRGPMEM.USER_KEY =' + ltrim(rtrim(str(@userKey)))

   execute sp_executesql @sql,N'@adminUser int output',@adminUser output
 
  --
  --message '@adminUser = '+str( @adminUser  );
  --
  -- if you are an admin, then you can see all groups
   if @adminUser > 0
   begin
	-- first get other accums

	  select CHILD_KEY,CHILD_TYPE,LONGNAME,GROUP_KEY,-1 as EXTRA_KEY,1 as CNT, ATTRIB from
	  APORTMAP join APRTINFO on APORTMAP.CHILD_KEY = APRTINFO.APORT_KEY where
	  APORTMAP.APORT_KEY = @parentNodeKey and CHILD_TYPE = 1 order by
	  LONGNAME asc;

	-- next get primary

	select A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY,-1 as EXTRA_KEY,count(B.CHILD_TYPE) as CNT, ATTRIB from
	  APORTMAP as A,APORTMAP as B,PPRTINFO where
	  A.CHILD_KEY = PPRTINFO.PPORT_KEY and
	  A.APORT_KEY = @parentNodeKey and A.CHILD_TYPE = 2 and
	  A.CHILD_TYPE = B.CHILD_TYPE and A.CHILD_KEY = B.CHILD_KEY
	  group by A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY, ATTRIB order by
	  LONGNAME asc;

	-- next get reins

	  select A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY,-1 as EXTRA_KEY,count(B.CHILD_TYPE) as CNT, ATTRIB from
	  APORTMAP as A,APORTMAP as B,RPRTINFO where
	  A.CHILD_KEY = RPRTINFO.RPORT_KEY and
	  A.APORT_KEY = @parentNodeKey and A.CHILD_TYPE = 3 and
	  A.CHILD_TYPE = B.CHILD_TYPE and A.CHILD_KEY = B.CHILD_KEY
	  group by A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY, ATTRIB order by
	  LONGNAME asc;

	-- next get Multi-treaty reins. We repeat the select statement to purposely display multi-treaty by group at the end

	  select A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY,-1 as EXTRA_KEY,count(B.CHILD_TYPE) as CNT, ATTRIB from
	  APORTMAP as A,APORTMAP as B,RPRTINFO where
	  A.CHILD_KEY = RPRTINFO.RPORT_KEY and
	  A.APORT_KEY = @parentNodeKey and A.CHILD_TYPE = 23 and
	  A.CHILD_TYPE = B.CHILD_TYPE and A.CHILD_KEY = B.CHILD_KEY
	  group by A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY, ATTRIB order by
	  LONGNAME asc

   end
   else
   begin
	-- first get other accums

	  select A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY,-1 as EXTRA_KEY,count(B.CHILD_TYPE) as CNT, ATTRIB from
	  APORTMAP as A,APORTMAP as B,APRTINFO where
	  A.CHILD_KEY = APRTINFO.APORT_KEY and
	  A.APORT_KEY = @parentNodeKey and A.CHILD_TYPE = 1 and
	  APRTINFO.GROUP_KEY = any(select USRGPMEM.GROUP_KEY from USRGPMEM join USERGRPS on
		USRGPMEM.GROUP_KEY = USERGRPS.GROUP_KEY where
		USRGPMEM.USER_KEY = @userKey and USERGRPS.GRP_READ = 'Y')
	  group by A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY, ATTRIB order by
	  LONGNAME asc;

	-- next get primary

	  select A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY,-1 as EXTRA_KEY,count(B.CHILD_TYPE) as CNT, ATTRIB from
	  APORTMAP as A,APORTMAP as B,PPRTINFO where
	  A.CHILD_KEY = PPRTINFO.PPORT_KEY and
	  A.APORT_KEY = @parentNodeKey and A.CHILD_TYPE = 2 and
	  A.CHILD_TYPE = B.CHILD_TYPE and A.CHILD_KEY = B.CHILD_KEY and
	  PPRTINFO.GROUP_KEY = any(select USRGPMEM.GROUP_KEY from USRGPMEM join USERGRPS on
		USRGPMEM.GROUP_KEY = USERGRPS.GROUP_KEY where
		USRGPMEM.USER_KEY = @userKey and USERGRPS.GRP_READ = 'Y')
	  group by A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY, ATTRIB order by
	  LONGNAME asc;

	-- next get reins

	select A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY,-1 as EXTRA_KEY,count(B.CHILD_TYPE) as CNT, ATTRIB from
	  APORTMAP as A,APORTMAP as B,RPRTINFO where
	  A.CHILD_KEY = RPRTINFO.RPORT_KEY and
	  A.APORT_KEY = @parentNodeKey and A.CHILD_TYPE = 3 and
	  A.CHILD_TYPE = B.CHILD_TYPE and A.CHILD_KEY = B.CHILD_KEY and
	  RPRTINFO.GROUP_KEY = any(select USRGPMEM.GROUP_KEY from USRGPMEM join USERGRPS on
		USRGPMEM.GROUP_KEY = USERGRPS.GROUP_KEY where
		USRGPMEM.USER_KEY = @userKey and USERGRPS.GRP_READ = 'Y')
	  group by A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY, ATTRIB order by
	  LONGNAME asc;

	-- next get Multi-treaty reins. We repeat the select statement to purposely display multi-treaty by group at the end

	select A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY,-1 as EXTRA_KEY,count(B.CHILD_TYPE) as CNT, ATTRIB from
	  APORTMAP as A,APORTMAP as B,RPRTINFO where
	  A.CHILD_KEY = RPRTINFO.RPORT_KEY and
	  A.APORT_KEY = @parentNodeKey and A.CHILD_TYPE = 23 and
	  A.CHILD_TYPE = B.CHILD_TYPE and A.CHILD_KEY = B.CHILD_KEY and
	  RPRTINFO.GROUP_KEY = any(select USRGPMEM.GROUP_KEY from USRGPMEM join USERGRPS on
		USRGPMEM.GROUP_KEY = USERGRPS.GROUP_KEY where
		USRGPMEM.USER_KEY = @userKey and USERGRPS.GRP_READ = 'Y')
	  group by A.CHILD_KEY,A.CHILD_TYPE,LONGNAME,GROUP_KEY, ATTRIB order by
	  LONGNAME asc
   end
end




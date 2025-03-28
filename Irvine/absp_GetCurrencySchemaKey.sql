if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetCurrencySchemaKey') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetCurrencySchemaKey
end
go

create procedure absp_GetCurrencySchemaKey
     @nodeKey  integer,
     @nodeType integer

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure returns the currency schema key for the given a node key and node type.
Returns:	Currency schema key.
====================================================================================================
</pre>
</font>
##BD_END

##PD  nodeKey ^^  The key of the node for which the currency schema name will be returned.
##PD  nodeType ^^  The type of node for which the currency schema name will be returned.
*/

as
begin

	set nocount on

	declare @key integer;
	execute @key = absp_FindNodeCurrencyKey @nodeKey, @nodeType;
	select @key = CURRSK_KEY from FLDRINFO where FOLDER_KEY = @key;

	return @key;

end

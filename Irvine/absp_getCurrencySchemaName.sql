if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getCurrencySchemaName') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getCurrencySchemaName
end

go

create procedure absp_getCurrencySchemaName 
     @currencySchemaName varchar(120) output,
     @nodeKey  integer,
     @nodeType  integer,
     @debugFlag integer = 0
 

/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQLSERVER
Purpose:

    This procedure returns the ultimate currency schema name for the given a node key and node type.

    
Returns:         Currency schema name.
                

====================================================================================================
</pre>
</font>
##BD_END

##PD  currencySchemaName ^^  Out parameter which will hold the currency schema name. 
##PD  nodeKey ^^  The key of the node for which the currency schema name will be returned. 
##PD  nodeType ^^  The type of node for which the currency schema name will be returned. 
##PD  debugFlag ^^  The debug flag


*/
as
begin  

	set nocount on

	declare @key integer;

	execute @key = absp_FindNodeCurrencyKey @nodeKey, @nodeType;

	select @key = CURRSK_KEY from FLDRINFO where FOLDER_KEY = @key;

	select @currencySchemaName = ltrim(rtrim(LONGNAME)) from CURRINFO where CURRSK_KEY = @key;
	
	if @currencySchemaName is null
	begin
		set @currencySchemaName = '';
	end
	
end;
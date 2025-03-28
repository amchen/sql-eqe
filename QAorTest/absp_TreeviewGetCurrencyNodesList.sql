if exists(select * from sysobjects where id = object_id(N'absp_TreeviewGetCurrencyNodesList') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewGetCurrencyNodesList
end

go
create procedure absp_TreeviewGetCurrencyNodesList 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:

    This procedure returns the list of all currency folders.
    

Returns:       A result set with five parameters:
		1. FOLDER_NAME	The name of the currency folder.
		2. SCHEMA_NAME	The name of the currency schema.
		3. FOLDER_KEY	Unique identifier for each folder( in this case, the currency folder).
				Assigned by the database autoincrement function.
		4. CURRSK_KEY	A unique sequential number for each currency schema.
				Assigned by the database autoincrement function.
		5. VALID_DAT	The date for which this schema was valid using server time.Format of YYYYMMDD.

               
====================================================================================================
</pre>
</font>
##BD_END

##RS  FOLDER_NAME ^^  The name of the currency folder.
##RS  SCHEMA_NAME ^^  The name of the currency schema.
##RS  FOLDER_KEY ^^  Unique identifier for each folder( in this case, the currency folder).Assigned by the database autoincrement function.
##RS  CURRSK_KEY ^^  A unique sequential number for each currency schema.Assigned by the database autoincrement function.
##RS  VALID_DAT ^^  The date for which this schema was valid using server time.Format of YYYYMMDD.
*/
as
begin
    select F.LONGNAME, C.LONGNAME, F.FOLDER_KEY, C.CURRSK_KEY, C.VALID_DAT
	from FLDRINFO F, CURRINFO C 
	where F.CURRSK_KEY = C.CURRSK_KEY and F.CURR_NODE = 'Y'
end






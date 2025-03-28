if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetDBOption') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetDBOption
end
go

create procedure absp_Util_GetDBOption @optionValue varchar(30)
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	SQL2005

Purpose:	This procedure checks if a given @@OPTIONS value is set to on or off.

Returns:        Returns 0 if the given @@OPTIONS is set to off, 1 if the given @@OPTIONS is set to on 
		and -1 with generated error if an invalid @@OPTIONS is passed.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @optionValue ^^  A valid @OPTIONS value to test.

##RD  @flag ^^  An integer that says whether the option is on or off.

*/
as
begin

   	declare @flag integer
	declare @optionBit integer
	set @flag = -1
   	select @optionBit = 
   	case @optionValue 
   		when 'DISABLE_DEF_CNST_CHK' then  1 
   		when 'IMPLICIT_TRANSACTIONS' then  2
		when 'CURSOR_CLOSE_ON_COMMIT' then  4
		when 'ANSI_WARNINGS' then 8
		when 'ANSI_PADDING' then 16
		when 'ANSI_NULLS' then 32
		when 'ARITHABORT' then 64
		when 'ARITHIGNORE' then 128
		when 'QUOTED_IDENTIFIER' then 256
		when 'NOCOUNT' then 512
		when 'ANSI_NULL_DFLT_ON' then 1024
		when 'ANSI_NULL_DFLT_OFF' then 2048
		when 'CONCAT_NULL_YIELDS_NULL' then 4096
		when 'NUMERIC_ROUNDABORT' then 8192
		when 'XACT_ABORT' then 16384 
		else -1 	
   	end
	if (@optionBit = -1)
	begin
		RAISERROR ('Invalid @@OPTIONS value has been passed. Please give a valid value.', 1, 1)
	end
	else
	begin
		if(@@OPTIONS & @optionBit > 0)
			set @flag = 1
		else if (@@OPTIONS & @optionBit = 0)
			set @flag = 0
	end
	return @flag
	
end
go

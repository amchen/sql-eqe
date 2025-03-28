if exists(select * from SYSOBJECTS where ID = object_id(N'absclr_GetPrivateProfileString') and objectproperty(ID,N'IsScalarFunction') = 1)
begin
   drop function absclr_GetPrivateProfileString
end
go

create function absclr_GetPrivateProfileString      
	(@lpAppName  varchar(255),   -- section name
    @lpKeyName  varchar(255),   -- key name
    @lpDefault  varchar(255),   -- default string
    @lpFileName varchar(255)    -- initialization file name
	)
returns varchar(255)
as
begin

    declare @theString char(255)
	set @theString=systemdb.dbo.clr_Util_GetProfileString(@lpAppName,@lpKeyName,@lpDefault,@lpFileName);
  
    return @theString
end;

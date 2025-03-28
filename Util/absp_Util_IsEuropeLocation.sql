IF EXISTS (SELECT 1 FROM sysobjects WHERE id = object_id('dbo.absp_Util_IsEuropeLocation'))
    DROP FUNCTION dbo.absp_Util_IsEuropeLocation;
GO

create function dbo.absp_Util_IsEuropeLocation (
	@Country_ID varchar(3)
)
returns integer
as
begin
    declare @IsEuropeLocation int;

	set @IsEuropeLocation = 0;

	if exists(select 1 from Country where Location='Europe' and Country_ID=@Country_ID)
		set @IsEuropeLocation = 1;

    return @IsEuropeLocation;
end

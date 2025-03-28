if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetRLobIdFromOccupancy') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_GetRLobIdFromOccupancy
end
go

create procedure absp_GetRLobIdFromOccupancy
	@countryId char(3),
	@state2 char(2),
	@eOccId int = 0,
	@eOccNo int = 0,
	@wOccId int = 0,
	@wOccNo int = 0
/*
##BD_BEGIN absp_GenericTableGetNewKey ^^ 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    ASA
Purpose:	This function determines RISKTYPE (R_LOB_ID) based on Occupancy for the U.S., Canada and Japan
		The function is based on Oakland G(OCCUPANCY) Rules 
			
Returns: R_LOB_ID 
====================================================================================================

</pre>
</font>
##BD_END

##PD  @countryId 	^^ Country ID
##PD  @state2	 	^^ 2-character of the state/province/cresta zone
##PD  @eOccId 		^^ Earthquake Occupancy Id
##PD  @eOccNo 		^^ Earthquake Occupancy No
##PD  @wOccId 		^^ Wind Occupancy Id
##PD  2wOccNo 		^^ Wind Occupancy No.
*/
as
begin
    set nocount on

    declare @isWindState int
    declare @jpnWndStates char(20)
    declare @eFundOcc int
    declare @wFundOcc int
    declare @fOcc int
    declare @rlobId int
    
    set @isWindState = 0 
    set @jpnWndStates = '09 10 11 12'	
    -- determine if wind state	
    	
    --if countryId = '01'
    -- Canada only supports Quake and @isWindState is initialized to 0, do nothing 
    --   set @isWindState = 0

    
    if @countryId = '00'
    begin  
       if exists(select 1 from statel where wind_valid='y' and country_id = '00'and state_2 = @state2) or @state2 = 'GM'
       begin
       	    set @isWindState = 1
       end
    end
    else if @countryId = '02' and charindex(@state2,@jpnWndStates,1) > 0
    begin
    	set @isWindState = 1
    end
    	
    	
    -- Calculate Fundamental Occupancy
    
    -- If wind occupancy is default (1) use quake occupancy
    -- If quake occupancy is default (1) use wind occupancy
    
    -- If neither occupancy is default, then based on the country use wind or quake occupancy as follows:
    --		USA -- If State is a wind State, use wind occupancy, else use Quake occupancy
    --		CAN -- Only Quake is supported, use quake occupancy
    --		JPN -- In Wind States (southwest of Osaka -- State in ('09', '10', '11', '12') use wind, else use Quake
    
    if @eOccNo <= 0
    	select @eOccNo = E_OCCPY_NO from EOTDL where E_OCCPY_ID = @eOccId and COUNTRY_ID = @countryId 
    	
    set @eFundOcc = (@eOccNo - 1) % 12 + 1
    
    if @wOccNo <= 0
    	select @wOccNo = W_OCCPY_NO from WOTDL where W_OCCPY_ID = @wOccId and COUNTRY_ID = @countryId 
    
    set @wFundOcc = @wOccNo
    	
    if @wOccId = 1 
        set @fOcc = @eFundOcc
    else if @eOccId = 1 
        set @fOcc = @wFundOcc
    else if @isWindState = 1
        set @fOcc = @wFundOcc
    else
        set @fOcc = @eFundOcc
    	    
    -- looking up R_LOB_ID
    	       
    select @rlobId = R_LOB_ID from ROCCTYPE where ROCC_ID = @fOcc
   
    --select @eOccId  eOccId, @eOccNo eOccNo, @wOccId wOccId, @wOccNo wOccNo, @isWindState isWindState,
    --  @eFundOcc eFundOcc, @wFundOcc wFundOcc, @fOcc fOcc, @rlobId rlobId 
          
    return @rlobId
	

end
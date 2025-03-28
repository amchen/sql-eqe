if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetJoinString') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetJoinString
end
 go

create procedure absp_GetJoinString @retString varchar(8000) out,@tableName1 varchar(120),@tableName2 varchar(120),@columnList varchar(8000)

as
begin
	set nocount on
		
	declare @idx int;   
	declare @col varchar(100)     
	
	set @idx = 1        
	set @retString='';
	
	while @idx!= 0     
	begin     
	    set @idx = charindex(',',@columnList)     
	    if @idx!=0     
	        set @col = left(@columnList,@idx - 1)     
	    else     
	        set @col = @columnList     
	
	    if(len(@col)>0)
	    begin
	    	set @retString=@retString + @tableName1 +'.' +@col + '=' + @tableName2 + '.' + @col + ' and ';
	    end
	    	
	
	    set @columnList = right(@columnList,len(@columnList) - @idx)     
	    if len(@columnList) = 0 break     
	end 
	set @retstring=left(@retString,len(@retstring)-3);
end

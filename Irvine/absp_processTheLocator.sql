if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_processTheLocator') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_processTheLocator
end
 go
create procedure absp_processTheLocator @results CHAR(40) output, @CID char(3),@LOC char(40)
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    ASA
Purpose:

This procedure formats a locator by attaching or removing the yearstring for a given county based 
on the rules in the LOCAPPND table.

[The rules in LOCAPPND are only applied  when translating the locators for three countries: Jamaica,
Puerto Rico, Portugal.  While displaying them in the GUI we would want to differentiate the old locators
having been used with the new added locators. For example, we will display the locators for Jamaica in 
the treeview as JAM-001*1999 and JAM-002*1999 for old locators and JAM-001and JAM-002 for new ones.
However, these locators are actually saved in the database as JAM-001, JAM-002 for the old ones and 
JAM-001*2002 and JAM-002*2002 for the new ones.  
So, when a locator is selected and saved via the GUI,  if the displayed locator is JAM-001*1999, the year
string *1999 will be removed (LOCAPPRULE = 'R' in LOCAPPND) from the locator and will be saved in the 
database as JAM-001. On the opposite, the displayed locator from the GUI, JAM-002, will be saved in the 
database as JAM-002*2002 using the append rule (LOCAPPRULE = 'A'). The LEAVE (='L') rule, which will 
leave the locator JAM-003*2002 the way it is without translation, is only used as a safeguard.]

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @CID ^^  The country identifier for which the locator is to be formatted.
##PD  @LOC ^^  The locator which is to be formatted.
##PD  @results ^^  The formatted locator (OUTPUT PARAMETER).
*/
as
begin

set nocount on
   declare @replacingYear char(10)
   declare @locCntryId char(3)
   declare @indx int
   declare @curs1_CountryId varchar(255)
   declare @curs1_LocAppRule varchar(255)
   declare @curs1_yearString varchar(255)
   
   set @replacingYear = ''
  --	message 'CID = ' + CID;
  --	message 'LOC = ' + LOC;
  --  Bring Cresta Zones up-to-date
  --  Locators are displayed in the treeview as JAM-001*1999 and JAM-003
  --  will be actually saved in the database as JAM-001 and JAM-003*2002
  --  based on the rules in LOCAPPND table.
  --  This is to display the locators in the formats that users expect to see.
  
   set @locCntryId = substring(@LOC,1,3)
  
   declare curs1  cursor fast_forward  for 
       select  COUNTRY_ID,LOCAPPRULE,rtrim(ltrim(YEARSTRING))  from #LOCAPPNDTMP where COUNTRY_ID = @CID
   open curs1
   fetch next from curs1 into @curs1_CountryId,@curs1_LocAppRule,@curs1_yearString
   while @@fetch_status = 0
   begin
      if @locCntryId = @CID
      begin
         -- the record with rec_type='A' is sorted and will be at the top
         if @curs1_LocAppRule = 'A'
         begin
            set @replacingYear = @curs1_yearString
         end
         
      -- message 'move on';
      -- if year string is found and it matches the replacingYear
      -- strip the replacingYear from the locator string
      
	else
	begin
	    set @indx =(select  charindex(@curs1_yearString,@LOC,1))
	    if @indx > 0
	    begin
		set @indx =(select  charindex(@curs1_yearString,@LOC,1))
		set @results = substring(@LOC,1,@indx -1)
		return
	    end
	    else
	    begin
		 -- no year string is found in the locator string
		 -- add back the removed year string to the locator String
		 -- else LOCAPPRULE = 'L' do nothing						
		 if charindex('*',@LOC) = 0
		begin
			   if @curs1_LocAppRule = 'R'
			   begin
				  set @results = rtrim(ltrim(@LOC))+@curs1_yearString
				   close curs1
				   deallocate curs1
				  return
			   end
		end
		end
         end
      end
      fetch next from curs1 into @curs1_CountryId,@curs1_LocAppRule,@curs1_yearString
   end
   close curs1
   deallocate curs1
   set @results = @LOC
   return
end


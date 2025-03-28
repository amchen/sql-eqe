if exists(select * from SYSOBJECTS where ID = object_id(N'absp_007935_CreateDefaultStructOccpyOverrides') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_007935_CreateDefaultStructOccpyOverrides;
end
go

create procedure  absp_007935_CreateDefaultStructOccpyOverrides  
as

begin
	set nocount on
	
	declare @sql varchar(max);
	
	if not exists (select 1 from sys.objects where name='DefaultStructOccpyOverrides' and type = 'U' )
	begin
		--Create table--
		exec absp_Util_CreateTableScript @sql out,'DefaultStructOccpyOverrides','','',1;
		exec (@sql);
			
		if exists (select 1 from SYS.TABLES where NAME = 'DefaultStructOccpyOverrides') 
		begin
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12001',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12003',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12005',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12007',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12013',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12019',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12023',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12029',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12031',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12033',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12037',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12039',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12041',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12045',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12047',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12059',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12063',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12065',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12067',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12073',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12077',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12079',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12089',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12091',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12107',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12109',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12113',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12121',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12123',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12125',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12129',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12131',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12133',8,'Residential',0,0,13138,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12009',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12011',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12015',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12017',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12021',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12027',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12035',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12043',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12049',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12051',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12053',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12055',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12057',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12061',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12069',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12071',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12075',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12081',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12083',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12085',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12086',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12087',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12093',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12095',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12097',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12099',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12101',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12103',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12105',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12111',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12115',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12117',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12119',8,'Residential',0,0,13139,0,0,0);
			insert into DEFAULTSTRUCTOCCPYOVERRIDES ( CountryKey , Country_ID , Fips , Rlobl_Grp_ID , Rlobl_Grp_Name , Str_Eq_ID , Str_Fd_ID , Str_Ws_ID , E_Occpy_ID , F_Occpy_ID , W_Occpy_ID ) values (1,'00','12127',8,'Residential',0,0,13139,0,0,0);
		end 
	end;
end;
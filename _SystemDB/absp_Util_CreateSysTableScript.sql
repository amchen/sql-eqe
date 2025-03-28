if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CreateSysTableScript') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateSysTableScript
end
go

create procedure absp_Util_CreateSysTableScript
	@ret_sqlScript 	varchar(max) output ,
	@baseTableName 	varchar(120) ,
	@newTableName 	varchar(120) = '' ,
	@dbSpaceName 	varchar(40) = '' ,
	@makeIndex 		int = 0 ,
	@autoKeyFlag 	int = 0,
	@destDbName     varchar(120) = ''
AS

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:       This procedure returns an SQL script as Output to create a table with the given
               newTableName in the specified dbSpace. The table script is based on the given
               system table name.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_sqlScript 	^^ SQL script returned as Output required to create a table.
##PD  @baseTableName 	^^ The name of the table based on which the 'create table' script for new table is generated.
##PD  @newTableName 	^^ The name of the new table for which the 'create table' script is to be generated
##PD  @dbSpaceName 		^^ The name of the dbspace on which the table is to reside.
##PD  @makeIndex 		^^ A Flag signifying if an index script is to be returned
##PD  @autoKeyFlag 		^^ A flag signifying if an auto increment key is to be used.
*/

begin

   set nocount on

   set ANSI_PADDING on

	Begin Try
		declare @sSql 				varchar(max)
		declare @sSql2 				varchar(max)
		declare @baseTableName2 	varchar(120)
		declare @targetTableName 	varchar(120)
		declare @dbSpaceName2 		varchar(300)
		declare @table_id 			int
		declare @NonClustered	    varchar(20)

		declare @numtypes 			nvarchar(80)
		declare	@dbname				sysname, @no varchar(35), @yes varchar(35), @none varchar(35)
		declare @objid 				int
		declare @Pk_List 			varchar(1000)

		declare @columnlist        varchar(8000)
		declare @cnstname          varchar(100)

		create Table #Table_Desc(
			Column_name 	varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS,
			Data_Type 		varchar(50)  COLLATE SQL_Latin1_General_CP1_CI_AS,
			Length 			int,
			Prec 			int,
			Scale 			int,
			Nullable 		varchar(10)  COLLATE SQL_Latin1_General_CP1_CI_AS,
			Default_Val 	varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS,
			Has_PK 			varchar (1) default 'N' COLLATE SQL_Latin1_General_CP1_CI_AS,
			RefIndx_Col 	varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS,
			Column_Id 		int,
			Seed_Value 		int,
			Increment_Value	int,
			is_RowGuidCol	int)

		select @no = 'no', @yes = 'yes', @none = 'none', @Pk_List = ''
		select @numtypes = N'tinyint,smallint,decimal,int,real,money,float,numeric,smallmoney'
		select @objid =  Object_ID(@baseTableName)

		declare @Column_Name 		varchar(100), @Column_ID Int, @Seed_Value Int, @Increment_Value Int, @is_RowGuidCol Int
		declare @Data_Type 			varchar(50), @Length Int, @Prec Int, @Scale Int, @Nullable varchar(10), @Default_Val Varchar(100), @Has_PK Varchar (1)
		declare @Constraint_Text 	nvarchar(4000)
		declare @ColID 				smallInt

		declare @index_id 			int
		declare @index_is_unique 	int
		declare @index_is_clustered bit
		declare @IndName 			varchar(300)

		declare @KeyColName 		varchar(300)
		declare @IndexScript 		varchar(max)


		set @baseTableName2 = rtrim(ltrim(@baseTableName))
		set @dbSpaceName2 = rtrim(ltrim(@dbSpaceName))
		-- handle case we do not need a separate target table
		set @targetTableName = Ltrim(Rtrim(@newTableName))
		if LEN(@targetTableName) = 0
			begin
				set @targetTableName = Ltrim(Rtrim(@baseTableName2))
			end

		if Not Exists(select 1 From SYS.SYSOBJECTS where NAME = @baseTableName2 And Type = 'U')
			begin
				set @ret_sqlScript = 'Util_CreateSysTableScript_ERROR_' + @baseTableName2 + '_NOT_IN_DATABASE';
				return;
			end
		else
			begin
				select @table_id = (Select Object_ID(@baseTableName2))
			end

		-- Check for matching dbspace [data file space] --
		If Exists (Select 1 From sys.data_spaces Where Name = @dbSpaceName)
			Begin
				Set @dbSpaceName2 = ' on ' + rtrim(ltrim(@dbSpaceName))
			End
		Else
			Begin
				Set @dbSpaceName2 = ''
			End



			if @destDbName = ''
				set @sSql =  'SET ANSI_PADDING OFF;SET ANSI_NULL_DFLT_ON ON;SET ANSI_NULLS ON;'
			else
			begin
				-- make sure the database is bracketed since it can contain spaces
				set @destDbName = replace(@destDbName,'[','')
				set @destDbName = replace(@destDbName,']','')
				set @destDbName = '[' + @destDbName + ']'
				set @sSql =  'use ' + @destDbName + ' SET ANSI_PADDING OFF;SET ANSI_NULL_DFLT_ON ON;SET ANSI_NULLS ON;'
			end

		Set @sSql = @sSql + ' create table ' + Ltrim(Rtrim(@targetTableName)) + ' ('

		-- Find Primary Keys --
		Declare @PK Table (Qualifier Varchar (500), Owner Varchar (50), TblName Varchar (50), Column_Name Varchar (50), Key_Seq Int, PK_Name Varchar (500))
		Insert Into @PK Exec sp_pkeys @baseTableName2

		-- Find Column Description --
		Insert Into #Table_Desc
		Select
			'Column_name'	= name,
			'Type'		= type_name(user_type_id),
			'Length'	= convert(int, max_length),
			'Prec'		= case when charindex(type_name(system_type_id), @numtypes) > 0
					       then convert(char(5),ColumnProperty(object_id, name, 'precision'))
					       else '     ' end,
			'Scale'		= case when charindex(type_name(system_type_id), @numtypes) > 0
					       then convert(char(5),OdbcScale(system_type_id,scale))
					       else '     ' end,
			'Nullable'	= case when is_nullable = 0 then @no else @yes end,
			'N', 'N', 'N',Column_Id, 0, 0, 0

		From sys.all_columns Where object_id = @objid
		Order By Column_Id

		-- Update Primary Key --
		Declare Cur_PK Cursor LOCAL For Select Column_Name From @PK Order By Key_Seq

		Open Cur_PK
			Fetch Next From Cur_PK Into @Column_Name

			While @@Fetch_Status = 0
				Begin
					Update #Table_Desc Set Has_PK = 'Y',Nullable=@none Where Column_Name = @Column_Name

					Fetch Next From Cur_PK Into @Column_Name
				End

		Close Cur_PK
		Deallocate Cur_PK

		-- Find Identity Column --
		update 	#Table_Desc
			set #Table_Desc.Seed_Value = Convert(int,sys.identity_columns.Seed_Value),
				#Table_Desc.Increment_Value = Convert(int,sys.identity_columns.Increment_Value),
				#Table_Desc.is_RowGuidCol = sys.identity_columns.is_RowGuidCol
			from  #Table_Desc, sys.identity_columns
			where #Table_Desc.Column_Id = sys.identity_columns.Column_Id
			and	  #Table_Desc.Column_Name = sys.identity_columns.Name
			and   sys.identity_columns.Object_id = @objid

		-- Find Default Values --
		Declare Cur_Default Cursor LOCAL For
		Select A.Name As Column_Name, B.Definition As Default_Definition
		From Sys.Columns A, Sys.Default_Constraints B
		Where	A.Object_Id = @objid
				And A.Object_Id = B.Parent_Object_Id
				And B.Type = 'D'
				And A.Column_ID = B.Parent_Column_ID

		Open Cur_Default
			Fetch Next From Cur_Default Into @Column_Name, @Constraint_Text

			While @@Fetch_Status = 0
				Begin
					-- Code to Add Default values to table creation script --
					Update #Table_Desc
						Set	Default_Val = @Constraint_Text
						Where Column_Name = @Column_Name

					Fetch Next From Cur_Default Into @Column_Name, @Constraint_Text
				End
		Close Cur_Default
		Deallocate Cur_Default

		-- check if table has a clustered index
		if exists (select 1 from SYS.INDEXES where object_id = @objid and type=1 and is_primary_key=0)
			begin
				set @NonClustered = ' NONCLUSTERED'
			end
		else
			begin
				set @NonClustered = ''
			end


		-- begin our create SQL statement --
		Declare CursScript Cursor LOCAL For
			Select	Column_name, Data_Type, Length, Prec, Scale, Nullable, Default_Val,
					Column_Id, Seed_Value, Increment_Value, is_RowGuidCol, Has_PK
			From #Table_Desc Order By Column_Id

		Open CursScript
		Fetch Next From CursScript Into @Column_name, @Data_Type, @Length, @Prec, @Scale, @Nullable, @Default_Val, @Column_Id, @Seed_Value, @Increment_Value, @is_RowGuidCol, @Has_PK
		While @@Fetch_Status = 0
			Begin
				If Upper(LTrim(RTrim(@Data_Type))) = 'INT'   Set @Data_Type = 'INT'
				If Upper(LTrim(RTrim(@Data_Type))) = 'FLOAT' Set @Data_Type = 'FLOAT (53)'
				If Upper(LTrim(RTrim(@Data_Type))) = 'REAL'  Set @Data_Type = 'FLOAT (24)'

				Set @sSql = @sSql + LTrim(RTrim(@Column_name)) + ' ' + Upper(LTrim(RTrim(@Data_Type)))

				-- Assign Scale & Prec --
				If (@Scale > 0)
					Begin
						If (@Prec + @Scale) > 0	And (Upper(LTrim(RTrim(@Data_Type ))) <> 'INT')
							Begin
								Set @sSql = LTrim(RTrim(@sSql)) + ' (' + LTrim(RTrim(Str(@Prec))) + ',' + LTrim(RTrim(Str(@Scale))) + ') '
							End
					End
				else
					Begin
						If (@Prec + @Scale) > 0	And (Upper(LTrim(RTrim(@Data_Type ))) = 'NUMERIC')
							Begin
								Set @sSql = LTrim(RTrim(@sSql)) + ' (' + LTrim(RTrim(Str(@Prec))) + ',' + LTrim(RTrim(Str(@Scale))) + ') '
							End
					End

				-- Length --
				If (@Length > 0)
					Begin
						If Upper(LTrim(RTrim(@Data_Type))) = 'CHAR' OR
						   Upper(LTrim(RTrim(@Data_Type))) = 'VARCHAR' OR
						   Upper(LTrim(RTrim(@Data_Type))) = 'NVARCHAR'
							Begin
								Set  @sSql = LTrim(RTrim(@sSql)) + ' (' +  LTrim(RTrim(Str(@Length))) + ')'
							End
					End

				-- (MAX) --
				If (@Length = -1)
					Begin
						If Upper(LTrim(RTrim(@Data_Type))) = 'VARCHAR' OR
						   Upper(LTrim(RTrim(@Data_Type))) = 'NVARCHAR' OR
						   Upper(LTrim(RTrim(@Data_Type))) = 'VARBINARY'
							Begin
								Set  @sSql = LTrim(RTrim(@sSql)) + ' (MAX) '
							End
					End

				-- Allow NULLS? --
				--if (@Nullable = 'no')
					--Begin
						--Set @sSql =  LTrim(RTrim(@sSql)) + ' NOT NULL '
					--End

				-- Default value --
				If Len(@Default_Val) > 1
					Begin
						-- strip parens
						Set @sSql = LTrim(RTrim(@sSql)) + ' DEFAULT ' + Replace(Replace(@Default_Val,'(', ''),')','')
					End

				-- Identity --
				If (@Seed_Value + @Increment_Value) > 0
					Begin
						Set @sSql = LTrim(RTrim(@sSql)) + ' IDENTITY(' + LTrim(RTrim(Str(@Seed_Value))) + ',' + LTrim(RTrim(Str(@Increment_Value))) + ')'
					End

				-- Set Primary Key --
				--If (@Has_PK = 'Y') Set @sSql = LTrim(RTrim(@sSql)) + ' PRIMARY KEY' + @NonClustered

				-- Add comma (,) to Script --
				Set @sSql = @sSql + ', '
				Fetch Next From CursScript Into @Column_name, @Data_Type, @Length, @Prec, @Scale, @Nullable, @Default_Val, @Column_Id, @Seed_Value, @Increment_Value, @is_RowGuidCol, @Has_PK
			End
			Close CursScript
			Deallocate CursScript



		--Add primary Key constraint
		set @cnstname = '';

		select top 1 @cnstname = s1.name, @NonClustered = s1.type_desc
			from sys.indexes s1
			inner join sys.objects s2 on s1.object_id = s2.object_id
				and SCHEMA_NAME(s2.schema_id) = SCHEMA_NAME()
				and object_name(s1.object_id) = @baseTableName and is_primary_key = 1;

		select @columnlist = COALESCE(@columnlist + ',', '') + '[' + index_col(@baseTableName, indID, KeyNo) + ']'
				from Sys.SysIndexKeys t1
				inner join sys.indexes t2 on t1.Id = t2.object_id And t1.indID =t2.index_id
				inner join sys.objects t3 on t2.object_id =t3.object_id
				and SCHEMA_NAME(t3.schema_id)=SCHEMA_NAME ()
				and object_name(t2.object_id) = @baseTableName and  is_primary_key =1	 Order By t1.KeyNo

		if rtrim(@newTableName)<>''
			set @cnstname = replace(rtrim(@cnstname), rtrim(@baseTableName), rtrim(@newTableName))

		if @cnstname <>''
			set @sSql = @sSql + 'CONSTRAINT [' + @cnstname + '] PRIMARY KEY '+ @NonClustered +' ( ' + @columnlist+' ))';
		else
			Set @sSql = SubString(@sSql,1, Len(ltrim(rtrim(@sSql))) - 1) + ')' + @dbSpaceName2-- Remove comma (,) to Script -

		IF @makeIndex > 0			-- Create Index Script
			Begin
			Declare @UniqueInd Varchar(10)
			Declare @ClusteredInd Varchar(15)
			Declare @FileGroup Varchar(50)
			Select @UniqueInd = '', @ClusteredInd = '', @FileGroup = ''

				-- makeIndex = 2 means return just the create index script
				Set @IndexScript = '';
				If @makeIndex = 2
					Begin
						Set @sSql = '';
					End
				Else
					Begin
						Set @sSql = @sSql + '; ';
					End
				-- Add Index Creation Script to Table Creation Script --
				Declare Cur_Index Cursor LOCAL For Select i.index_id, i.name, i.is_unique, INDEXPROPERTY(i.object_id, i.name,'IsClustered'),d.name as FileGrp
											from sys.indexes i, sys.stats s, sys.data_spaces d
											Where i.object_id = s.object_id
											And i.index_id = s.stats_id
											And i.object_id = @objid
											And i.data_space_id = d.data_space_id
											And i.is_primary_key = 0
											order by i.name

				Open Cur_Index
					Fetch Next From Cur_Index Into @index_id, @IndName, @index_is_unique, @index_is_clustered, @FileGroup
						While @@Fetch_Status = 0
							Begin
								If @index_is_unique = 1  Set @UniqueInd = ' UNIQUE'

								If @index_is_clustered = 1  Set @ClusteredInd = ' CLUSTERED'

								Set @IndexScript = @IndexScript + 'CREATE' + @UniqueInd + @ClusteredInd + ' INDEX ' + @IndName + ' ON ' + Ltrim(Rtrim(@targetTableName)) + ' ( '

								Declare Cur_Index_Keys Cursor LOCAL For
									Select  index_col(@baseTableName, indID, KeyNo) As IndColName
									From Sys.SysIndexKeys Where Id = @objid
									And indID =@index_id  Order By KeyNo

								Open Cur_Index_Keys
								Fetch Next From Cur_Index_Keys Into @KeyColName
									While @@Fetch_Status = 0
										Begin
											Set @IndexScript = @IndexScript + @KeyColName + ',' ;

											Fetch Next From Cur_Index_Keys Into @KeyColName
										End

								Set @IndexScript = SubString(@IndexScript,1, Len(@IndexScript) -1)
								Close Cur_Index_Keys
								Deallocate Cur_Index_Keys

								If @dbSpaceName2 = ' on ' + @FileGroup
									Begin
										Set @IndexScript = @IndexScript + ' )' + ' on ' + @FileGroup + ';'
									End
								Else
									Begin
										Set @IndexScript = @IndexScript + ' );'
									End
								Select @UniqueInd = '', @ClusteredInd = '', @FileGroup = ''
					Fetch Next From Cur_Index Into @index_id, @IndName, @index_is_unique, @index_is_clustered, @FileGroup
							End
				Close Cur_Index
				Deallocate Cur_Index
			End
		-- Final Script --
		If Len (LTrim(RTrim(@IndexScript))) > 0
			Begin
				Set @ret_sqlScript =  LTrim(RTrim(LTrim(RTrim(@sSql)) + ' '+  LTrim(RTrim(@IndexScript))))
			End
		Else
			Begin
				Set @ret_sqlScript =  LTrim(RTrim(@sSql))
			End
	   drop Table #Table_Desc

	   set ANSI_PADDING off

	   RETURN
	End Try

	Begin Catch
		if exists(select 1 from tempdb.Information_Schema.Tables where Table_Name Like '#Table_Desc%')
		begin
			drop Table #Table_Desc
		end
		Select Error_Line(), Error_Message(), Error_Procedure()
	End Catch

	set ANSI_PADDING off

end

if exists(select 1 from SYSOBJECTS where id = object_id(N'absp_QAorTest_CQ7UpdateTextColumn') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure absp_QAorTest_CQ7UpdateTextColumn
end
go

CREATE PROC absp_QAorTest_CQ7UpdateTextColumn
(
    @nRowCount int output,
    @SearchStr nvarchar(100),
    @ReplaceStr nvarchar(100),
    @TableName nvarchar(256),
    @ColumnName nvarchar(128)
)
AS
BEGIN

    set @nRowCount = 0
        
    -- CQ [defect] table
    if (@TableName = '[dba].[defect]')
    begin
    
        set xact_abort on
        begin tran

        declare @txtlen int
        set @txtlen = len(@SearchStr) - 2

        declare @ptr        binary(16)
        declare @pos        int
        declare @id         varchar(100)
        declare @sSql       varchar(max)
        declare @sSql2      varchar(max)

        if (@ColumnName = '[analysis]')
        begin
            --select id, textptr([analysis]), charindex(3.11.00,[analysis]) - 1 from [dba].[ChangeRequest] where [analysis] like '%'3.11.00'%'
            declare curs_analysis cursor local fast_forward for
                select id, textptr([analysis]), patindex(@SearchStr, [analysis]) - 1
                    from [dba].[defect]
                    where [analysis]
                    like @SearchStr

            open curs_analysis
            fetch next from curs_analysis into @id, @ptr, @pos

            while @@fetch_status = 0
            begin
                print 'Text string found in Defect ' + cast(@id as varchar) + ' at Position ' + cast(@pos as varchar)
                updatetext [dba].[defect].[analysis] @ptr @pos @txtlen @ReplaceStr
                set @nRowCount = @nRowCount + 1
                fetch next from curs_analysis into @id, @ptr, @pos   
            end

            close curs_analysis
            deallocate curs_analysis
        end

        if (@ColumnName = '[attached_references]')
        begin
            declare curs_attached_references cursor local fast_forward for
                select id, textptr([attached_references]), patindex(@SearchStr, [attached_references]) - 1
                    from [dba].[defect]
                    where [attached_references]
                    like @SearchStr

            open curs_attached_references
            fetch next from curs_attached_references into @id, @ptr, @pos

            while @@fetch_status = 0
            begin
                print 'Text string found in Defect ' + cast(@id as varchar) + ' at Position ' + cast(@pos as varchar)
                updatetext [dba].[defect].[attached_references] @ptr @pos @txtlen @ReplaceStr
                set @nRowCount = @nRowCount + 1
                fetch next from curs_attached_references into @id, @ptr, @pos   
            end

            close curs_attached_references
            deallocate curs_attached_references
        end

        if (@ColumnName = '[problem_description]')
        begin
            declare curs_problem_description cursor local fast_forward for
                select id, textptr([problem_description]), patindex(@SearchStr, [problem_description]) - 1
                    from [dba].[defect]
                    where [problem_description]
                    like @SearchStr

            open curs_problem_description
            fetch next from curs_problem_description into @id, @ptr, @pos

            while @@fetch_status = 0
            begin
                print 'Text string found in Defect ' + cast(@id as varchar) + ' at Position ' + cast(@pos as varchar)
                updatetext [dba].[defect].[problem_description] @ptr @pos @txtlen @ReplaceStr
                set @nRowCount = @nRowCount + 1
                fetch next from curs_problem_description into @id, @ptr, @pos   
            end

            close curs_problem_description
            deallocate curs_problem_description
        end

        if (@ColumnName = '[resolution_description]')
        begin
            declare curs_resolution_description cursor local fast_forward for
                select id, textptr([resolution_description]), patindex(@SearchStr, [resolution_description]) - 1
                    from [dba].[defect]
                    where [resolution_description]
                    like @SearchStr

            open curs_resolution_description
            fetch next from curs_resolution_description into @id, @ptr, @pos

            while @@fetch_status = 0
            begin
                print 'Text string found in Defect ' + cast(@id as varchar) + ' at Position ' + cast(@pos as varchar)
                updatetext [dba].[defect].[resolution_description] @ptr @pos @txtlen @ReplaceStr
                set @nRowCount = @nRowCount + 1
                fetch next from curs_resolution_description into @id, @ptr, @pos   
            end

            close curs_resolution_description
            deallocate curs_resolution_description
        end

        if (@ColumnName = '[verification_description]')
        begin
            declare curs_verification_description cursor local fast_forward for
                select id, textptr([verification_description]), patindex(@SearchStr, [verification_description]) - 1
                    from [dba].[defect]
                    where [verification_description]
                    like @SearchStr

            open curs_verification_description
            fetch next from curs_verification_description into @id, @ptr, @pos

            while @@fetch_status = 0
            begin
                print 'Text string found in Defect ' + cast(@id as varchar) + ' at Position ' + cast(@pos as varchar)
                updatetext [dba].[defect].[verification_description] @ptr @pos @txtlen @ReplaceStr
                set @nRowCount = @nRowCount + 1
                fetch next from curs_verification_description into @id, @ptr, @pos   
            end

            close curs_verification_description
            deallocate curs_verification_description
        end

        commit tran
    end
END

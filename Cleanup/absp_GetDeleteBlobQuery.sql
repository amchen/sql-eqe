if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetDeleteBlobQuery') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_GetDeleteBlobQuery
end

go

create procedure absp_GetDeleteBlobQuery
	@sqlout	varchar(1000) output,
	@TN		varchar(120),
	@KN		varchar(120),
	@delRows int,
	@delTtype char(1),
	@XW		varchar(255) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    ASA
Purpose:

    This procedure builds the delele BLOB query given table name, key field name, key value and extra where clause

Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END
##PD  @TN       ^^ tablename.
##PD  @KN       ^^ keyname.
##PD  @delRows	^^ number of deleted rows
##PD  @delTtype	^^ delete type ('B' or 'K')
##PD  @sqlout	^^ output sql string
##PD  @XW       ^^ extra where clause.

*/

as

BEGIN
    declare @theKey     int;
    declare @endMsg     varchar(20);
    declare @sqldel     varchar(20);
    declare @sqlcond    varchar(20);
    declare @sql1       nvarchar(4000)
    declare @msg        varchar(1000);
    declare @me 		varchar(100);


    set @me = 'absp_GetDeleteBlobQuery';

    set @msg = @me + ' Starting...';
    exec absp_Util_Log_HighLevel @msg, @me;

    set @sqldel = 'delete ';
    set @sqlcond = ' < 0 ';
    set @theKey = 0;

    set @msg = 'select max(' + @KN + ') into @theKey from ' + @TN + ' where ' + @KN + ' < 0 ' + @XW;
    exec absp_Util_Log_HighLevel @msg, @me;
    set @sql1 =N'select @theKey = max('+ @KN + ') from ' + @TN + ' where ' + @KN + ' < 0 ' + @XW;
    --print @sql1
    execute sp_executesql @sql1, N'@theKey int output',@theKey output;

    if @theKey is null set @theKey = 0

    --print '***@theKey = ' + ltrim(rtrim((str(@theKey))))
    --print '***@delRows= ' +ltrim(rtrim((str(@delRows))))

    if (@delRows > 0)
    begin
        set @sqldel = ltrim(rtrim(@sqldel)) + ' top(' + ltrim(rtrim((str(@delRows)))) + ')';
        --print '***@sqldel= ' + @sqldel
    end

    if @delTtype = 'B'
         set @sqlcond = ' < 0 '
    else if @delTtype = 'K'
        set @sqlcond = ' = '+ rtrim(ltrim(str(@theKey))) + ' '

    --print  '*** @delTtype= ' + @delTtype

    set @sqlout = @sqldel + ' from ' + @TN + ' where ' + @KN + @sqlcond + @XW;
    set @sqlout = rtrim(ltrim(@sqlout))

    --print  '*** @sqlout= ' + @sqlout
    --print  '*** @theKey= ' + str(@theKey)

    return @theKey
    --select @sql;
 end
if exists(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.usp_ClearTable') AND type in (N'P', N'PC'))
	drop procedure dbo.usp_ClearTable
go

create procedure dbo.usp_ClearTable
	@TableNAme nvarchar(max),	-- Table name for claering
	@DatetimeField nvarchar(max), --Fild name with date
	@DayAgo int,				-- Day Ago
	@StatisticsOnly  bit		-- 1- Return Statistic Only 0 - Delete
as begin
	set nocount on
	
	declare @CountAll bigint 
	declare @CountToDelete bigint 
	declare @LastDay date = dateadd(day,-@DayAgo,getdate())
	
	if exists(select 1 as exist from sys.objects where object_id = OBJECT_ID(@TableNAme,N'U')) begin
		print 'Table "'+ @TableNAme + '" exists.'
		if exists(select 1 as exist from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableNAme and COLUMN_NAME = @DatetimeField and DATA_TYPE in('datetime','date')) begin
			print 'Table "'+ @TableNAme + '" has column "' + @DatetimeField +'"'
			if @StatisticsOnly = 1 begin
				declare @Sql_Statistic nvarchar(max) = 'select @CountAll = count(1),@CountToDelete = sum(case when ['+@DatetimeField+'] < @LastDay then 1 else 0 end) from ['+@TableNAme+']'
				execute sp_executesql @Sql_Statistic,N'@CountAll bigint output, @CountToDelete bigint output,@LastDay date',@CountAll = @CountAll output,@CountToDelete = @CountToDelete output,@LastDay=@LastDay
				print 'Will be deleted ' + cast(@CountToDelete as nvarchar) + ' from ' + cast(@CountAll as nvarchar)+ ' rows'
			end	else begin
				declare @Sql_Delete nvarchar(max) = 'delete from ['+@TableNAme+'] where ['+@DatetimeField+'] < @LastDay
														set @CountToDelete = @@ROWCOUNT'
				execute sp_executesql @Sql_Delete,N'@CountToDelete bigint output,@LastDay date',@CountToDelete = @CountToDelete output,@LastDay= @LastDay
				print cast(@CountToDelete as nvarchar) + ' rows were deleted'
			end	
		end else
			print 'Table "'+ @TableNAme + '" does not have column "' + @DatetimeField + '" or column "' + @DatetimeField + '" does not date_type = "DATE".'
	end else
		print 'Table "' + @TableNAme + '" do not exists.'

	set nocount off
end
go



-- Author     : If it works, it Siddharth B
-- Date       : 19 JAN 2020 ... It's 2020 already! Where are the flying cars?
-- Description: Display database object stats like number of tables, number of
--              views, triggers of multiple databases. Useful for quickly 
--              evaluating the complexity of a database schema.

use master;

if object_id('tempdb..#result') is not null drop table #result;
create table #result
(
	DatabaseName varchar(100) not null, 
	NoOfTables int not null default(0),
	NoOfViews int not null default(0),
	NoOfSPs int not null default(0),
	AvgColsPerTable int not null default(0),
	MaxColsInAnyTable int not null default(0),
	NoOfTriggers int not null default(0)
);

if object_id('tempdb..#tableResult') is not null drop table #tableResult;
create table #tableResult
(
	DatabaseName varchar(100) not null, 
	TableName varchar(100) not null,
	NoOfColumns int not null default (0),
	NoOfTriggers int not null default(0)
);

declare @sqlcode nvarchar(max) 
set @sqlcode = '
declare @tables table
(
	Id int primary key not null identity(1,1), 
	object_id int unique,
	name varchar(100) not null
);

declare @colCount int = 0;
declare @avgColsPerTable int = 0;
declare @triggerCount int = 0;

declare @rowCount int = 0;
declare @tableName nvarchar(100);

insert into @tables(object_id, name) 
select object_id, name from sys.tables;	

declare @tableCounter int = 1;
declare @tableCount int;

select @tableCount = count(*) from @tables;

declare @currentTable varchar(100);
declare @currentTableObjectId int;
declare @currentDbName varchar(100) = DB_NAME();

while (@tableCounter < @tableCount) begin	
	select @currentTable = t.name, @currentTableObjectId = object_id from @tables t where t.Id = @tableCounter;

	select @colCount = count(column_id) from sys.columns c where c.object_id = @currentTableObjectId; 
	select @triggerCount = count(name) from sys.triggers t where parent_id = @currentTableObjectId;
	
	insert into #tableResult(DatabaseName, TableName, NoOfColumns, NoOfTriggers)	
	select @currentDbName, @currentTable, @colCount, @triggerCount;
	
	set @tableCounter = @tableCounter + 1;
end

declare @viewCount int = 0;
select @viewCount = count(*) from sys.views;

declare @spCount int = 0;
select @spCount = count(*) from sys.procedures;

declare @totalColCount int;
select @totalColCount = sum(NoOfColumns) from #tableResult where DatabaseName = DB_NAME();
select @avgColsPerTable = @totalColCount / (select count(*) from @tables);

declare @maxColsInAnyTable int;
select @maxColsInAnyTable = max(NoOfColumns) from #tableResult where DatabaseName = DB_NAME();
	
declare @totalTriggerCount int;
select @totalTriggerCount = sum(NoOfTriggers) from #tableResult where DatabaseName = DB_NAME();

insert into #result(DatabaseName, NoOfTables, NoOfSPs, NoOfViews, AvgColsPerTable, MaxColsInAnyTable, NoOfTriggers)
select @currentDbName, @tableCount, @spCount, @viewCount, @avgColsPerTable, @maxColsInAnyTable, @totalTriggerCount;
';

declare @databases table
(	
	id int not null identity(1,1) primary key,
	DbName varchar(100) not null unique
);

insert into @databases(DbName)
select name from sys.databases where name not in ('master', 'model', 'msdb', 'tempdb');

declare @dbcount int = 0;
select @dbcount = count(*) from @databases;

declare @dbcounter int = 1;
declare @dbName nvarchar(100);
declare @sql nvarchar(max);

while (@dbcounter <= @dbcount) begin
	select @dbName = DbName from @databases where Id = @dbCounter;	
	set @sql = N'USE ' + @dbName + ';' + CHAR(13) + @sqlcode;
	execute sp_executesql @sql;	
	set @dbcounter = @dbcounter + 1;
end

select * from #tableResult;
select * from #result;
go

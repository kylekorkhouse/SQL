--Query > Results to File...(Ctrl + Shift + FLOAT
--Set file path, all query results should return in file.
--K. Korkhouse / 01-30-2015

--PART B: Aprimo Instance Health
SET NOCOUNT ON;
SET STATISTICS TIME OFF;
-- **** Switch to your Aprimo database *****
USE APRIMO_DATABASE_NAME;
GO

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'1. Individual File Sizes and space available for current database';
SELECT name AS [File Name], physical_name AS [Physical Name], size/128.0 AS [Total Size in MB],
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS [Available Space In MB], [file_id]
FROM sys.database_files WITH (NOLOCK) OPTION (RECOMPILE);

PRINT N'	Look at how large and how full the files are and where they are located;
	Make sure the transaction log is not full!!';

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'2. Get transaction log size and space information for the current database';
SELECT DB_NAME(database_id) AS [Database Name], database_id,
CAST((total_log_size_in_bytes/1048576.0) AS DECIMAL(10,1)) 
AS [Total_log_size(MB)],
CAST((used_log_space_in_bytes/1048576.0) AS DECIMAL(10,1)) 
AS [Used_log_space(MB)],
CAST(used_log_space_in_percent AS DECIMAL(10,1)) AS [Used_log_space(%)]
FROM sys.dm_db_log_space_usage WITH (NOLOCK) OPTION (RECOMPILE);

PRINT N'	Another way to look at transaction log file size and space'

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'3. I/O Statistics by file for the current database';
SELECT DB_NAME(DB_ID()) AS [Database Name],[file_id], num_of_reads, num_of_writes, io_stall_read_ms, io_stall_write_ms,
CAST(100. * io_stall_read_ms/(io_stall_read_ms + io_stall_write_ms) 
AS DECIMAL(10,1)) AS [IO Stall Reads Pct],
CAST(100. * io_stall_write_ms/(io_stall_write_ms + io_stall_read_ms) 
AS DECIMAL(10,1)) AS [IO Stall Writes Pct],
(num_of_reads + num_of_writes) AS [Writes + Reads], num_of_bytes_read, num_of_bytes_written,
CAST(100. * num_of_reads/(num_of_reads + num_of_writes) AS DECIMAL(10,1)) 
AS [# Reads Pct],
CAST(100. * num_of_writes/(num_of_reads + num_of_writes) AS DECIMAL(10,1)) 
AS [# Write Pct],
CAST(100. * num_of_bytes_read/(num_of_bytes_read + num_of_bytes_written) 
AS DECIMAL(10,1)) AS [Read Bytes Pct],
CAST(100. * num_of_bytes_written/(num_of_bytes_read + num_of_bytes_written) 
AS DECIMAL(10,1)) AS [Written Bytes Pct]
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL) OPTION (RECOMPILE);

PRINT N'	This helps you characterize your workload better from an I/O perspective';

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'4. Get VLF count for transaction log for the current database,
	number of rows equals the VLF count. Lower is better!';
	PRINT N'';
DBCC LOGINFO;
	PRINT N'';
PRINT N'	High VLF counts can affect write performance 
	and they can make database restore and recovery take much longer'

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'5. Top cached queries by Execution Count (SQL Server 2012)'
SELECT qs.execution_count, qs.total_rows, qs.last_rows, qs.min_rows, qs.max_rows,
qs.last_elapsed_time, qs.min_elapsed_time, qs.max_elapsed_time,
SUBSTRING(qt.TEXT,qs.statement_start_offset/2 +1,
(CASE WHEN qs.statement_end_offset = -1
      THEN LEN(CONVERT(NVARCHAR(MAX), qt.TEXT)) * 2
 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) 
AS query_text
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY qs.execution_count DESC OPTION (RECOMPILE);

PRINT N'	Uses several new rows returned columns 
	to help troubleshoot performance problems' 


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'6. Top Cached SPs By Execution Count (SQL Server 2012)';
SELECT TOP(250) p.name AS [SP Name], qs.execution_count,
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) 
AS [Calls/Second],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.total_worker_time AS [TotalWorkerTime],qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
qs.cached_time
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.execution_count DESC OPTION (RECOMPILE);

PRINT N'	Tells you which cached stored procedures are called the most often
	This helps you characterize and baseline your workload';

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'7. Top Cached SPs By Avg Elapsed Time (SQL Server 2012)'
SELECT TOP(25) p.name AS [SP Name], qs.total_elapsed_time/qs.execution_count 
AS [avg_elapsed_time], qs.total_elapsed_time, qs.execution_count, ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, 
GETDATE()), 0) AS [Calls/Second], 
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.total_worker_time AS [TotalWorkerTime], qs.cached_time
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY avg_elapsed_time DESC OPTION (RECOMPILE);

PRINT N'	This helps you find long-running cached stored procedures that
	may be easy to optimize with standard query tuning techniques';

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'8. Top Cached SPs By Total Worker time (SQL Server 2012). Worker time relates to CPU cost';
SELECT TOP(25) p.name AS [SP Name], qs.total_worker_time AS [TotalWorkerTime], 
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], qs.execution_count, 
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) 
AS [Calls/Second],qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count 
AS [avg_elapsed_time], qs.cached_time
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE);

PRINT N'	This helps you find the most expensive cached 
	stored procedures from a CPU perspective. You should look at 
	this if you see signs of CPU pressure'

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'9. Top Cached SPs By Total Logical Reads (SQL Server 2012). 
	Logical reads relate to memory pressure,'
SELECT TOP(25) p.name AS [SP Name], qs.total_logical_reads 
AS [TotalLogicalReads], qs.total_logical_reads/qs.execution_count 
AS [AvgLogicalReads],qs.execution_count, 
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) 
AS [Calls/Second], qs.total_elapsed_time,qs.total_elapsed_time/qs.execution_count 
AS [avg_elapsed_time], qs.cached_time
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_logical_reads DESC OPTION (RECOMPILE);

PRINT N'	This helps you find the most expensive cached 
	stored procedures from a memory perspective
	You should look at this if you see signs of memory pressure'

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'10. Top Cached SPs By Total Physical Reads (SQL Server 2012). 
	Physical reads relate to disk I/O pressure'
SELECT TOP(25) p.name AS [SP Name],qs.total_physical_reads 
AS [TotalPhysicalReads],qs.total_physical_reads/qs.execution_count 
AS [AvgPhysicalReads], qs.execution_count, qs.total_logical_reads, qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count 
AS [avg_elapsed_time], qs.cached_time 
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
AND qs.total_physical_reads > 0
ORDER BY qs.total_physical_reads DESC, 
qs.total_logical_reads DESC OPTION (RECOMPILE);


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'11. Top Cached SPs By Total Logical Writes (SQL Server 2012). 
	Logical writes relate to both memory and disk I/O pressure'
SELECT TOP(25) p.name AS [SP Name], qs.total_logical_writes 
AS [TotalLogicalWrites], qs.total_logical_writes/qs.execution_count 
AS [AvgLogicalWrites], qs.execution_count,
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) 
AS [Calls/Second],qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], qs.cached_time
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_logical_writes DESC OPTION (RECOMPILE);

PRINT N'	This helps you find the most expensive cached 
	stored procedures from a write I/O perspective
	You should look at this if you see signs of I/O pressure or of memory pressure'


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';


PRINT N'12. Lists the top statements by average input/output 
	usage for the current database'
SELECT TOP(50) OBJECT_NAME(qt.objectid) AS [SP Name],
(qs.total_logical_reads + qs.total_logical_writes) /qs.execution_count 
AS [Avg IO],SUBSTRING(qt.[text],qs.statement_start_offset/2, 
(CASE 
 WHEN qs.statement_end_offset = -1 
 THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 
 ELSE qs.statement_end_offset 
 END - qs.statement_start_offset)/2) AS [Query Text]	
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.[dbid] = DB_ID()
ORDER BY [Avg IO] DESC OPTION (RECOMPILE);

PRINT N'	Helps you find the most expensive statements for I/O by SP'

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';



PRINT N'13. Missing Indexes current database by Index Advantage'
SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) 
AS [index_advantage], 
migs.last_user_seek, mid.[statement] AS [Database.Schema.Table],
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID() -- Remove this to see for entire instance
ORDER BY index_advantage DESC OPTION (RECOMPILE);

PRINT N'	Look at last user seek time, number of user seeks 
	to help determine source and importance
	SQL Server is overly eager to add included columns, so beware
	Do not just blindly add indexes that show up from this query!!!'

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'14. Breaks down buffers used by current database 
	by object (table, index) in the buffer cache'
SELECT OBJECT_NAME(p.[object_id]) AS [ObjectName], 
p.index_id, COUNT(*)/128 AS [Buffer size(MB)],  COUNT(*) AS [BufferCount], 
p.data_compression_desc AS [CompressionType]
FROM sys.allocation_units AS a WITH (NOLOCK)
INNER JOIN sys.dm_os_buffer_descriptors AS b WITH (NOLOCK)
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p WITH (NOLOCK)
ON a.container_id = p.hobt_id
WHERE b.database_id = CONVERT(int,DB_ID())
AND p.[object_id] > 100
GROUP BY p.[object_id], p.index_id, p.data_compression_desc
ORDER BY [BufferCount] DESC OPTION (RECOMPILE);

PRINT N'	Tells you what tables and indexes are 
	using the most memory in the buffer cache'
PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'15. When were Statistics last updated on all indexes?';
SELECT o.name, i.name AS [Index Name],STATS_DATE(i.[object_id], 
i.index_id) AS [Statistics Date], s.auto_created, 
s.no_recompute, s.user_created, st.row_count
FROM sys.objects AS o WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON o.[object_id] = i.[object_id]
INNER JOIN sys.stats AS s WITH (NOLOCK)
ON i.[object_id] = s.[object_id] 
AND i.index_id = s.stats_id
INNER JOIN sys.dm_db_partition_stats AS st WITH (NOLOCK)
ON o.[object_id] = st.[object_id]
AND i.[index_id] = st.[index_id]
WHERE o.[type] = 'U'
ORDER BY STATS_DATE(i.[object_id], i.index_id) ASC OPTION (RECOMPILE);  

PRINT N'	Helps discover possible problems with out-of-date statistics
	Also gives you an idea which indexes are most active';

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';



PRINT N'16. Get fragmentation info for all indexes 
	above a certain size in the current database 
	Note: This could take some time on a very large database'
SELECT DB_NAME(database_id) AS [Database Name], 
OBJECT_NAME(ps.OBJECT_ID) AS [Object Name], 
i.name AS [Index Name], ps.index_id, index_type_desc,
avg_fragmentation_in_percent, fragment_count, page_count
FROM sys.dm_db_index_physical_stats(DB_ID(),NULL, NULL, NULL ,'LIMITED') AS ps
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON ps.[object_id] = i.[object_id] 
AND ps.index_id = i.index_id
WHERE database_id = DB_ID()
AND page_count > 500
ORDER BY avg_fragmentation_in_percent DESC OPTION (RECOMPILE);

PRINT N'	Helps determine whether you have fragmentation in your relational indexes
	and how effective your index maintenance strategy is'


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
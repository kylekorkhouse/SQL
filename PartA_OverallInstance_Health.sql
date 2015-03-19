SET NOCOUNT ON;
SET STATISTICS TIME OFF;
--Query > Results to File...(Ctrl + Shift + FLOAT
--Set file path, all query results should return in file.
--K. Korkhouse / 01-30-2015

--PART A: Overall Instance Health
PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'1.  SQL and OS Version information for current instance'
SELECT @@VERSION AS [SQL Server and OS Version Info];

-- SQL Server 2012 Builds
-- Build		Description
-- 11.00.1055		CTP0
-- 11.00.1103		CTP1
-- 11.00.1540		CTP3
-- 11.00.1515		CTP3 plus Test Update
-- 11.00.1750		RC0
-- 11.00.1913       RC1
-- 11.00.2300       RTM
-- 11.00.2316       RTM CU1
-- 11.00.2325       RTM CU2
-- 11.00.2809		SP1 CTP3 (un-supported in production)	

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'2. Windows information (SQL Server 2012)'
SELECT windows_release, windows_service_pack_level, 
       windows_sku, os_language_version
FROM sys.dm_os_windows_info WITH (NOLOCK) OPTION (RECOMPILE);

-- Gives you major OS version, Service Pack, Edition, 
-- and language info for the operating system

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'3. Hardware information from SQL Server 2012 (new virtual_machine_type_desc)'
PRINT N'(Cannot distinguish between HT and multi-core)'
SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],cpu_count/hyperthread_ratio AS [Physical CPU Count], 
physical_memory_kb/1024 AS [Physical Memory (MB)], 
affinity_type_desc, virtual_machine_type_desc, sqlserver_start_time
FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);

-- Gives you some good basic hardware information about your database server
PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';

PRINT N'4. Get System Manufacturer and model number from 
SQL Server Error log. This query might take a few seconds 
if you have not recycled your error log recently'
EXEC xp_readerrorlog 0,1,"Manufacturer"; 

-- This can help you determine the capabilities
-- and capacities of your database server

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'5. Get processor description from Windows Registry'
EXEC xp_instance_regread 
'HKEY_LOCAL_MACHINE',
'HARDWARE\DESCRIPTION\System\CentralProcessor\0',
'ProcessorNameString';

-- Gives you the model number and rated clock speed of your processor(s)

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'6. SQL Server Services information from SQL Server 2012'
SELECT servicename, startup_type_desc, status_desc,
last_startup_time, service_account, is_clustered, cluster_nodename
FROM sys.dm_server_services WITH (NOLOCK) OPTION (RECOMPILE);

-- Gives you information about your installed SQL Server Services, 
-- whether they are clustered, and which node owns the cluster resources

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'7. Shows you where the SQL Server error log is located and how it is configured'
SELECT is_enabled, [path], max_size, max_files
FROM sys.dm_os_server_diagnostics_log_configurations WITH (NOLOCK) 
OPTION (RECOMPILE);

-- Knowing this information is important for troubleshooting purposes

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'8. Get information about your OS cluster (if your database server is in a cluster)'
SELECT VerboseLogging, SqlDumperDumpFlags, SqlDumperDumpPath, 
       SqlDumperDumpTimeOut, FailureConditionLevel, HealthCheckTimeout
FROM sys.dm_os_cluster_properties WITH (NOLOCK) OPTION (RECOMPILE);

-- You will see no results if your instance is not clustered

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'9. Get information about your cluster nodes and their status (if your database server is in a cluster)'
SELECT NodeName, status_description, is_current_owner
FROM sys.dm_os_cluster_nodes WITH (NOLOCK) OPTION (RECOMPILE);

-- Knowing which node owns the cluster resources is critical
-- Especially when you are installing Windows or SQL Server updates

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'10. Get configuration values for instance'
SELECT name, value, value_in_use, [description] 
FROM sys.configurations WITH (NOLOCK)
ORDER BY name OPTION (RECOMPILE);

-- Focus on
-- backup compression default
-- clr enabled (only enable if it is needed)
-- lightweight pooling (should be zero)
-- max degree of parallelism 
-- max server memory (MB) (set to an appropriate value)
-- optimize for ad hoc workloads (should be 1)
-- priority boost (should be zero)

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'Get information about TCP Listener for SQL Server'
SELECT listener_id, ip_address, is_ipv4, port, type_desc, state_desc, start_time
FROM sys.dm_tcp_listener_states WITH (NOLOCK) OPTION (RECOMPILE);

-- Helpful for network and connectivity troubleshooting

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'12. SQL Server Registry information'
SELECT registry_key, value_name, value_data
FROM sys.dm_server_registry WITH (NOLOCK) OPTION (RECOMPILE);

-- This lets you safely read some SQL Server related 
-- information from the Windows Registry

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'13. Get information on location, time and size of any memory dumps from SQL Server'
SELECT [filename], creation_time, size_in_bytes
FROM sys.dm_server_memory_dumps WITH (NOLOCK) OPTION (RECOMPILE);

-- This will not return any rows if you have 
-- not had any memory dumps (which is a good thing)

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'14. File Names and Paths for Tempdb and all user databases in instance'
SELECT DB_NAME([database_id])AS [Database Name], 
       [file_id], name, physical_name, type_desc, state_desc, 
       CONVERT( bigint, size/128.0) AS [Total Size in MB]
FROM sys.master_files WITH (NOLOCK)
WHERE [database_id] > 4 
AND [database_id] <> 32767
OR [database_id] = 2
ORDER BY DB_NAME([database_id]) OPTION (RECOMPILE);

-- Things to look at:
-- Are data files and log files on different drives?
-- Is everything on the C: drive?
-- Is TempDB on dedicated drives?
-- Are there multiple data files?

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'15. Recovery model, log reuse wait description, log file size, log usage size 
		and compatibility level for all databases on instance'
SELECT db.[name] AS [Database Name], db.recovery_model_desc AS [Recovery Model], 
db.log_reuse_wait_desc AS [Log Reuse Wait Description], 
ls.cntr_value AS [Log Size (KB)], lu.cntr_value AS [Log Used (KB)],
CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS 
[Log Used %], db.[compatibility_level] AS [DB Compatibility Level], 
db.page_verify_option_desc AS [Page Verify Option], db.is_auto_create_stats_on, 
db.is_auto_update_stats_on, db.is_auto_update_stats_async_on, db.is_parameterization_forced, 
db.snapshot_isolation_state_desc, db.is_read_committed_snapshot_on,
is_auto_shrink_on, is_auto_close_on 
FROM sys.databases AS db WITH (NOLOCK)
INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)
ON db.name = lu.instance_name
INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK)
ON db.name = ls.instance_name
WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%' 
AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
AND ls.cntr_value > 0 OPTION (RECOMPILE);

-- Things to look at:
-- How many databases are on the instance?
-- What recovery models are they using?
-- What is the log reuse wait description?
-- How full are the transaction logs?
-- What compatibility level are they on?


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'16. Calculates average stalls per read, per write, 
			and per total input/output for each database file.'
SELECT DB_NAME(fs.database_id) AS [Database Name], mf.physical_name, io_stall_read_ms, num_of_reads,
CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],io_stall_write_ms, 
num_of_writes,CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],
io_stall_read_ms + io_stall_write_ms AS [io_stalls], num_of_reads + num_of_writes AS [total_io],
CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) 
AS [avg_io_stall_ms]
FROM sys.dm_io_virtual_file_stats(null,null) AS fs
INNER JOIN sys.master_files AS mf WITH (NOLOCK)
ON fs.database_id = mf.database_id
AND fs.[file_id] = mf.[file_id]
ORDER BY avg_io_stall_ms DESC OPTION (RECOMPILE);

-- Helps determine which database files on 
-- the entire instance have the most I/O bottlenecks

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'17. Get total buffer usage by database for current instance'
SELECT DB_NAME(database_id) AS [Database Name],
COUNT(*) * 8/1024.0 AS [Cached Size (MB)]
FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
WHERE database_id > 4 -- system databases
AND database_id <> 32767 -- ResourceDB
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC OPTION (RECOMPILE);

-- Tells you how much memory (in the buffer pool) 
-- is being used by each database on the instance

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'18. Get CPU utilization by database';
WITH DB_CPU_Stats
AS
(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], 
 SUM(total_worker_time) AS [CPU_Time_Ms]
 FROM sys.dm_exec_query_stats AS qs
 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
              FROM sys.dm_exec_plan_attributes(qs.plan_handle)
              WHERE attribute = N'dbid') AS F_DB
 GROUP BY DatabaseID)
SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
       DatabaseName, [CPU_Time_Ms], 
       CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) 
	   OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
FROM DB_CPU_Stats
WHERE DatabaseID > 4 -- system databases
AND DatabaseID <> 32767 -- ResourceDB
ORDER BY row_num OPTION (RECOMPILE);

-- Helps determine which database is 
-- using the most CPU resources on the instance

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'19. Isolate top waits for server instance since last restart or statistics clear';
WITH Waits AS
(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s,
100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
FROM sys.dm_os_wait_stats WITH (NOLOCK)
WHERE wait_type NOT IN (N'CLR_SEMAPHORE',N'LAZYWRITER_SLEEP',N'RESOURCE_QUEUE',
N'SLEEP_TASK',N'SLEEP_SYSTEMTASK',N'SQLTRACE_BUFFER_FLUSH',N'WAITFOR', 
N'LOGMGR_QUEUE',N'CHECKPOINT_QUEUE', N'REQUEST_FOR_DEADLOCK_SEARCH',
N'XE_TIMER_EVENT',N'BROKER_TO_FLUSH',N'BROKER_TASK_STOP',N'CLR_MANUAL_EVENT',
N'CLR_AUTO_EVENT',N'DISPATCHER_QUEUE_SEMAPHORE', N'FT_IFTS_SCHEDULER_IDLE_WAIT',
N'XE_DISPATCHER_WAIT', N'XE_DISPATCHER_JOIN', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
N'ONDEMAND_TASK_QUEUE', N'BROKER_EVENTHANDLER', N'SLEEP_BPOOL_FLUSH',
N'DIRTY_PAGE_POLL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 
N'SP_SERVER_DIAGNOSTICS_SLEEP'))

SELECT W1.wait_type, 
CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 99 OPTION (RECOMPILE); -- percentage threshold

-- Clear Wait Stats 
-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'20. Signal Waits for instance'
SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [%signal (cpu) waits],
CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [%resource waits]
FROM sys.dm_os_wait_stats WITH (NOLOCK) OPTION (RECOMPILE);

-- Signal Waits above 15-20% is usually a sign of CPU pressure

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'21. Get logins that are connected and how many sessions they have '
SELECT login_name, COUNT(session_id) AS [session_count] 
FROM sys.dm_exec_sessions WITH (NOLOCK)
GROUP BY login_name
ORDER BY COUNT(session_id) DESC OPTION (RECOMPILE);

-- This can help characterize your workload and
-- determine whether you are seeing a normal level of activity

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'22. Get Average Task Counts'
SELECT AVG(current_tasks_count) AS [Avg Task Count], 
AVG(runnable_tasks_count) AS [Avg Runnable Task Count],
AVG(pending_disk_io_count) AS [Avg Pending DiskIO Count]
FROM sys.dm_os_schedulers WITH (NOLOCK)
WHERE scheduler_id < 255 OPTION (RECOMPILE);

-- Sustained values above 10 suggest further investigation in that area
-- High Avg Task Counts are often caused by blocking or other resource contention
-- High Avg Runnable Task Counts are a good sign of CPU pressure
-- High Avg Pending DiskIO Counts are a sign of disk pressure

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'23. Get CPU Utilization History for last 256 minutes (in one minute intervals)'
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks) 
                          FROM sys.dm_os_sys_info WITH (NOLOCK)); 

SELECT TOP(256) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
                SystemIdle AS [System Idle Process], 
                100 - SystemIdle - SQLProcessUtilization 
                AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), 
               GETDATE()) AS [Event Time] 
FROM (SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 		record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]',     'int') 
AS[SystemIdle],record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]','int') 
			AS [SQLProcessUtilization], [timestamp] 
	  FROM (SELECT [timestamp], CONVERT(xml, record) AS [record] 
		 FROM sys.dm_os_ring_buffers WITH (NOLOCK)
		 WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
		 AND record LIKE N'%<SystemHealth>%') AS x 
	  ) AS y 
ORDER BY record_id DESC OPTION (RECOMPILE);

-- Look at the trend over the entire period. 
-- Also look at high sustained Other Process CPU Utilization values

PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'24. Basic information about OS memory amounts and state'
SELECT total_physical_memory_kb, available_physical_memory_kb, 
       total_page_file_kb, available_page_file_kb, 
       system_memory_state_desc
FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);

-- You want to see "Available physical memory is high"
-- This indicates that you are not under external memory pressure


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'25. SQL Server Process Address space info 
		(shows whether locked pages is enabled, among other things)'
SELECT physical_memory_in_use_kb,locked_page_allocations_kb, 
       page_fault_count, memory_utilization_percentage, 
       available_commit_limit_kb, process_physical_memory_low, 
       process_virtual_memory_low
FROM sys.dm_os_process_memory WITH (NOLOCK) OPTION (RECOMPILE);

-- You want to see 0 for process_physical_memory_low
-- You want to see 0 for process_virtual_memory_low
-- This indicates that you are not under internal memory pressure


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'26. Page Life Expectancy (PLE) value for default instance'
SELECT cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Buffer Manager%' -- Handles named instances
AND counter_name = N'Page life expectancy' OPTION (RECOMPILE);

-- PLE is one way to measure memory pressure.
-- Higher PLE is better. Watch the trend, not the absolute value.


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'27. Memory Grants Outstanding value for default instance'
SELECT cntr_value AS [Memory Grants Outstanding]                                                                                                      
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Memory Manager%' -- Handles named instances
AND counter_name = N'Memory Grants Outstanding' OPTION (RECOMPILE);

-- Memory Grants Outstanding above zero 
-- for a sustained period is a secondary indicator of memory pressure


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'28. Memory Grants Pending value for default instance'
SELECT cntr_value AS [Memory Grants Pending]                                                                                                      
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Memory Manager%' -- Handles named instances
AND counter_name = N'Memory Grants Pending' OPTION (RECOMPILE);

-- Memory Grants Pending above zero 
-- for a sustained period is an extremely strong indicator of memory pressure


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'29. Memory Clerk Usage for instance
			Look for high value for CACHESTORE_SQLCP (Ad-hoc query plans)'
SELECT TOP(10) [type] AS [Memory Clerk Type], 
       SUM(pages_kb) AS [SPA Mem, Kb] 
FROM sys.dm_os_memory_clerks WITH (NOLOCK)
GROUP BY [type]  
ORDER BY SUM(pages_kb) DESC OPTION (RECOMPILE);

-- CACHESTORE_SQLCP  SQL Plans         
-- These are cached SQL statements or batches that 
-- aren't in stored procedures, functions and triggers
--
-- CACHESTORE_OBJCP  Object Plans      
-- These are compiled plans for 
-- stored procedures, functions and triggers
--
-- CACHESTORE_PHDR   Algebrizer Trees  
-- An algebrizer tree is the parsed SQL text 
-- that resolves the table and column names


PRINT N'';
PRINT N'==============================================================================================================================================================================================================================';
PRINT N'';
PRINT N'30. Find single-use, ad-hoc queries that are bloating the plan cache'
SELECT TOP(20) [text] AS [QueryText], cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE cp.cacheobjtype = N'Compiled Plan' 
AND cp.objtype = N'Adhoc' 
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC OPTION (RECOMPILE);

-- Gives you the text and size of single-use ad-hoc queries that 
-- waste space in the plan cache
-- Enabling 'optimize for ad hoc workloads' for the instance 
-- can help (SQL Server 2008 and above only)
-- Enabling forced parameterization for the database can help, but test first!
--PURPOSE: Move next retry time dates forward
--Kyle K. - 03 / 17 / 2015

---MAKE A TEMP TABLE TO PULL TASK IDs FROM
CREATE TABLE #WF_TASK_STAGING (WF_TASK_ID int NOT NULL,);

--POPULATE IT WITH TASK IDS
INSERT INTO #WF_TASK_STAGING
SELECT t.task_id 
FROM projects p
inner join wf_tasks t
	on t.project_id = p.project_id
		where p.project_status = 2
		AND t.task_status in (2,7)
order by t.task_id


--See how many rows were dealing with
DECLARE @ROWS_REMAINING int;
SET @ROWS_REMAINING = (SELECT COUNT(*) FROM #WF_TASK_STAGING);

--Info Statement Only
PRINT @ROWS_REMAINING

--START MAIN LOOP
WHILE (@ROWS_REMAINING > 100)
BEGIN
	
	BEGIN TRAN
	UPDATE WF_TASKS SET NEXT_RETRY_TIME = DATEADD(dd,63*DATEPART(dd,begin_date),Next_RETRY_TIME)
	where task_id IN(SELECT TOP 100 WF_TASK_ID from #WF_TASK_STAGING order by WF_TASK_ID)

	DELETE FROM #WF_TASK_STAGING
	WHERE WF_TASK_ID IN (SELECT TOP 100 WF_TASK_ID from #WF_TASK_STAGING order by WF_TASK_ID)

	COMMIT

	SET @ROWS_REMAINING = @ROWS_REMAINING - 100;
	

	--Info Statement Only
	PRINT @ROWS_REMAINING;

END;
--END MAIN LOOP

--Cleanup Table
DROP TABLE #WF_TASK_STAGING
GO


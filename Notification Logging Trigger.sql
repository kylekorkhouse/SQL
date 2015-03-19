---Notification Logging Trigger
---Kyle Korkhouse - 03-19-2014

--See if table already exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[notification_audit]') AND type in (N'U'))
DROP TABLE [dbo].[notification_audit]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[notification_audit_msgs]') AND type in (N'U'))
DROP TABLE [dbo].[notification_audit_msgs]
GO

--Pre-load audit table if there's anything already in notifications table
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
GO
BEGIN TRANSACTION;
GO
Begin
	Select 
		notification_id,
		source,
		encoding_charset,
		priority,
		ready_to_send,
		created_date,
		sender_id,
		subject,
		sender_address,
		message_type,
		p_ID,
		outbound_priority,
		error_message,
		interaction_id,
		bounced_email_addr,
		Cast('Historical' as nvarchar(50)) as 'audit_action',
		Cast(GETUTCDATE() as datetime) as audit_create_date,
		Cast(Null as nvarchar(max)) as audit_sql,
		Cast(Null as nvarchar(max)) as audit_stack_trace,
		Cast(Null as nvarchar(500)) as audit_app
	Into notification_audit 
	From notification
End
GO

BEGIN
	SELECT notification_id,message
	into notification_audit_msgs
	FROM notification
END
GO

COMMIT TRANSACTION;
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_notification_audit]') )
DROP TRIGGER [dbo].trg_notification_audit
GO
CREATE TRIGGER dbo.trg_notification_audit
   ON dbo.notification
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	Declare @audit_action varchar(50) = 'Unknown';
	Declare @audit_sql nvarchar(max)
	Declare @isUpdating int = 0;

	DECLARE @TEMP TABLE 
	(EventType NVARCHAR(30), Parameters INT, EventInfo nvarchar(max)) 
	INSERT INTO @TEMP EXEC('DBCC INPUTBUFFER(@@SPID)') 

	Set @audit_sql = (Select Distinct EventInfo From @TEMP);
	
	If (Exists(Select 1 From inserted) 
		And Exists(Select 1 From deleted))
		Set @isUpdating = 1;
	
	If (Exists(select 1 from inserted))
	Begin
		If (@isUpdating = 0)
			Set @audit_action = 'Insert';
		Else
			Set @audit_action = 'UpdateInsert';
		
		Insert Into notification_audit
		(
				notification_id,
				source,
				encoding_charset,
				priority,
				ready_to_send,
				created_date,
				sender_id,
				subject,
				sender_address,
				message_type,
				p_ID,
				outbound_priority,
				error_message,
				interaction_id,
				bounced_email_addr,
				audit_action, 
				audit_create_date,
				audit_sql,
				audit_app
		)
		Select			
				notification_id,
				source,
				encoding_charset,
				priority,
				ready_to_send,
				created_date,
				sender_id,
				subject,
				sender_address,
				message_type,
				p_ID,
				outbound_priority,
				error_message,
				interaction_id,
				bounced_email_addr,
				@audit_action, 
				GETUTCDATE(),
				@audit_sql,
				APP_NAME()
		From inserted i 

		INSERT INTO notification_audit_msgs
		SELECT notification_id, message from dbo.notifications where notification_id = (Select notification_id from inserted) 
	End

	
	If (Exists(select 1 from deleted))
	Begin
		If (@isUpdating = 0)
			Set @audit_action = 'Delete';
		Else
			Set @audit_action = 'UpdateDelete';
		
		Insert Into notification_audit
		(
				notification_id,
				source,
				encoding_charset,
				priority,
				ready_to_send,
				created_date,
				sender_id,
				subject,
				sender_address,
				message_type,
				p_ID,
				outbound_priority,
				error_message,
				interaction_id,
				bounced_email_addr,
				audit_action, 
				audit_create_date,
				audit_sql,
				audit_app
		)
		Select			
				notification_id,
				source,
				encoding_charset,
				priority,
				ready_to_send,
				created_date,
				sender_id,
				subject,
				sender_address,
				message_type,
				p_ID,
				outbound_priority,
				error_message,
				interaction_id,
				bounced_email_addr,
				@audit_action, 
				GETUTCDATE(),
				@audit_sql,
				APP_NAME()
		From deleted d
		
		INSERT INTO notification_audit_msgs
		SELECT notification_id, message from notifications where notification_id = (Select notification_id from deleted) 
	
	End
End
Go

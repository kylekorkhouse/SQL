USE [PURPHARMAAMS_PROD_HOST138_20150305_cm186033]
GO
/****** Object:  Trigger [dbo].[trg_notification_audit]    Script Date: 3/31/2015 7:44:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER [dbo].[trg_notification_audit]
   ON [dbo].[notification]
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
		SELECT notification_id, message from dbo.notification where notification_id = (Select top 1 notification_id from inserted) 
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
		SELECT notification_id, message from notification where notification_id = (Select top 1 notification_id from deleted) 
	
	End
End

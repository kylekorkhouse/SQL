-- AMS-3246 start
IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[annotations_audit]') AND type in (N'U'))
Begin
	Select 
		annotation_id,
		object_type_id,
		object_id,
		annotation_type_id,
		comments,
		role_id,
		status,
		style,
		page,
		location,
		print_number,
		ref_doc_id,
		ref_doc_page,
		tag_id,
		modified_user,
		modified_date,
		creator_id,
		created_date,
		pdf_id,
		orig_role_id,
		carry_fwd_id,
		context_page_id,
		context_object_id,
		context_object_type_id,
		context_type,
		video_start_time_sec,
		video_end_time_sec,
		avl_date,
		Cast('Historical' as nvarchar(50)) as 'audit_action',
		Cast(GETUTCDATE() as datetime) as audit_create_date,
		Cast(Null as nvarchar(max)) as audit_sql,
		Cast(Null as nvarchar(max)) as audit_stack_trace,
		Cast(Null as nvarchar(500)) as audit_app
	Into annotations_audit From annotations
End
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SaveAnnotationsFromOffline_aud]') AND type in (N'U'))
CREATE TABLE [dbo].[SaveAnnotationsFromOffline_aud](
	AprimoUsername varchar(1000) NULL,
	DSN varchar(1000) NULL,
	strDomainID varchar(1000) NULL,
	strObjectID varchar(1000) NULL,
	strObjectTypeID varchar(1000) NULL,
	list varchar(max) NULL,
	UserChoice varchar(1000) NULL,
	ConflictList varchar(max) NULL,
	lastSynchDate varchar(1000) NULL,
	ssoLoginName varchar(1000) NULL,
	[expireDate] varchar(1000) NULL
) ON [PRIMARY]
GO

-- clean up old name
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_Annotations_INSERT_UPDATE_DELETE]') )
DROP TRIGGER [dbo].trg_Annotations_INSERT_UPDATE_DELETE
-- new oracle name due to 30 char limit
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_Annotations_Audit]') )
DROP TRIGGER [dbo].trg_Annotations_Audit
GO
CREATE TRIGGER dbo.trg_Annotations_Audit
   ON  dbo.annotations
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
		
		Insert Into annotations_audit
		(
				annotation_id,
				object_type_id,
				object_id,
				annotation_type_id,
				comments,
				role_id,
				status,
				style,
				page,
				location,
				print_number,
				ref_doc_id,
				ref_doc_page,
				tag_id,
				modified_user,
				modified_date,
				creator_id,
				created_date,
				pdf_id,
				orig_role_id,
				carry_fwd_id,
				context_page_id,
				context_object_id,
				context_object_type_id,
				context_type,
				video_start_time_sec,
				video_end_time_sec,
				avl_date,
				audit_action, 
				audit_create_date,
				audit_sql,
				audit_app
		)
		Select			
				annotation_id,
				object_type_id,
				object_id,
				annotation_type_id,
				comments,
				role_id,
				status,
				style,
				page,
				'location can''t be audited becuase it''s a text data type',
				print_number,
				ref_doc_id,
				ref_doc_page,
				tag_id,
				modified_user,
				modified_date,
				creator_id,
				created_date,
				pdf_id,
				orig_role_id,
				carry_fwd_id,
				context_page_id,
				context_object_id,
				context_object_type_id,
				context_type,
				video_start_time_sec,
				video_end_time_sec,
				avl_date,
				@audit_action, 
				GETUTCDATE(),
				@audit_sql,
				APP_NAME()
		From inserted
	End

	
	If (Exists(select 1 from deleted))
	Begin
		If (@isUpdating = 0)
			Set @audit_action = 'Delete';
		Else
			Set @audit_action = 'UpdateDelete';
		
		Insert Into annotations_audit
		(
				annotation_id,
				object_type_id,
				object_id,
				annotation_type_id,
				comments,
				role_id,
				status,
				style,
				page,
				location,
				print_number,
				ref_doc_id,
				ref_doc_page,
				tag_id,
				modified_user,
				modified_date,
				creator_id,
				created_date,
				pdf_id,
				orig_role_id,
				carry_fwd_id,
				context_page_id,
				context_object_id,
				context_object_type_id,
				context_type,
				video_start_time_sec,
				video_end_time_sec,
				avl_date,
				audit_action, 
				audit_create_date,
				audit_sql,
				audit_app
		)
		Select			
				annotation_id,
				object_type_id,
				object_id,
				annotation_type_id,
				comments,
				role_id,
				status,
				style,
				page,
				'location can''t be audited becuase it''s a text data type',
				print_number,
				ref_doc_id,
				ref_doc_page,
				tag_id,
				modified_user,
				modified_date,
				creator_id,
				created_date,
				pdf_id,
				orig_role_id,
				carry_fwd_id,
				context_page_id,
				context_object_id,
				context_object_type_id,
				context_type,
				video_start_time_sec,
				video_end_time_sec,
				avl_date,
				@audit_action, 
				GETUTCDATE(),
				@audit_sql,
				APP_NAME()
		From deleted
	End
End
Go
-- AMS-3246 end
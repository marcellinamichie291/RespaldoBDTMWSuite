CREATE TABLE [dbo].[TASK_FILTER]
(
[TASK_FILTER_ID] [int] NOT NULL IDENTITY(1, 1),
[FILTER_NAME] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TASK_ID] [int] NULL,
[NAME] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ASSIGNED_USER] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[USER_DEFINED_TYPE1] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[USER_DEFINED_TYPE2] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[USER_DEFINED_TYPE3] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[USER_DEFINED_TYPE4] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DATE_FILTERS] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STATUS] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[START_DUE_DATE] [datetime] NULL,
[END_DUE_DATE] [datetime] NULL,
[LEAD_TIME_FLAG] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORD_NUMBER] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORD_BILLTO] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORD_SHIPPER] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACTIVE_FLAG] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEFAULT_FLAG] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[USER_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CREATED_DATE] [datetime] NOT NULL,
[CREATED_USER] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MODIFIED_DATE] [datetime] NOT NULL,
[MODIFIED_USER] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TASK_TEMPLATE_ID] [int] NULL,
[ENTITY_TABLE_ID] [int] NULL,
[AUTO_FILTER_FLAG] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TASK_FILTER] ADD CONSTRAINT [PK__TASK_FILTER__7644C4CF] PRIMARY KEY CLUSTERED ([TASK_FILTER_ID]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[TASK_FILTER] TO [public]
GO
GRANT INSERT ON  [dbo].[TASK_FILTER] TO [public]
GO
GRANT REFERENCES ON  [dbo].[TASK_FILTER] TO [public]
GO
GRANT SELECT ON  [dbo].[TASK_FILTER] TO [public]
GO
GRANT UPDATE ON  [dbo].[TASK_FILTER] TO [public]
GO
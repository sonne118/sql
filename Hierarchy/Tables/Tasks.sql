USE PMSHierarchyDB;
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON;
GO
CREATE TABLE dbo.Tasks (
    [t_id]          INT                 IDENTITY (1, 1) NOT NULL,
    [p_id]          INT                 NOT NULL,
    [t_name]        VARCHAR (25)        NULL,
    [t_description] VARCHAR (50)        NULL,
    [t_hid]         [sys].[hierarchyid] NOT NULL,
    [t_lvl]         AS                  ([t_hid].[GetLevel]()) PERSISTED,
    [t_startdate]   DATE                NOT NULL,
    [t_finishdate]  DATE                NOT NULL,
    [t_state]       INT                 NOT NULL,
    PRIMARY KEY CLUSTERED ([t_id] ASC),
    CONSTRAINT [FK_ProjetTask] FOREIGN KEY ([p_id]) REFERENCES [dbo].[Projects] ([p_id]) ON DELETE CASCADE
);
USE PMSHierarchyDB;
SET ANSI_NULLS, QUOTED_IDENTIFIER ON;
GO
CREATE TABLE [dbo].[Projects] (
    [p_id]         INT                 IDENTITY (1, 1) NOT NULL,
    [p_code]       INT                 NOT NULL,
    [p_hid]        [sys].[hierarchyid] NOT NULL,
    [p_lvl]        AS                  ([p_hid].[GetLevel]()) PERSISTED,
    [p_name]       VARCHAR (25)        NOT NULL,
    [p_startdate]  DATE                NOT NULL,
    [p_finishdate] DATE                NOT NULL,
    PRIMARY KEY CLUSTERED ([p_id] ASC)
);
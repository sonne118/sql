USE PMSHierarchyDB;
GO
CREATE TYPE [dbo].[MemoryReportTable] AS TABLE (
    [p_id]          INT          NULL,
    [p_code]        INT          NULL,
    [p_name]        VARCHAR (50) NULL,
    [p_lvl]         INT          NULL,
    [p_startdate]   DATE         NULL,
    [p_finishdate]  DATE         NULL,
    [p_state]       VARCHAR (10) NULL,
    [t_id]          INT          NULL,
    [t_name]        VARCHAR (50) NULL,
    [t_description] VARCHAR (50) NULL,
    [t_lvl]         INT          NULL,
    [t_startdate]   DATE         NULL,
    [t_finishdate]  DATE         NULL,
    [t_state]       VARCHAR (10) NULL,
    INDEX [MemoryReportTable] ([p_id]));


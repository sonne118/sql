USE PMSHierarchyDB;
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC dbo.Add_Task_And_Project
  @p_code AS INT, @p_mgrid AS INT = 0, @p_name AS VARCHAR(25) = "Project 1",
  @p_startdate AS DATE = '2008-01-01', @p_finishdate AS DATE = '2008-12-31'
AS  
     DECLARE @p_hid AS HIERARCHYID, @t_hid AS HIERARCHYID,
             @p_mgr_hid AS HIERARCHYID,@p_last_child_hid AS HIERARCHYID, 
             @Identity AS INT, @t_state AS INT = 0,
             @t_name AS INT = NULL
          
    IF @p_mgrid = 0  
      IF(NOT EXISTS(SELECT 1 FROM dbo.Projects))
        SET @p_hid = hierarchyid::GetRoot().GetDescendant(NULL,NULL);
      ELSE
        SET @p_hid =  hierarchyid::GetRoot().GetDescendant((select MAX(p_hid) from dbo.Projects where p_hid.GetAncestor(1) = hierarchyid::GetRoot()),NULL)
    ELSE 
       BEGIN              
      SET @p_mgr_hid = (SELECT p_hid FROM dbo.Projects WHERE p_id = @p_mgrid);  
      SET @p_last_child_hid =
        (SELECT MAX(p_hid) FROM dbo.Projects
         WHERE p_hid.GetAncestor(1) = @p_mgr_hid); 
         SET @p_hid = @p_mgr_hid.GetDescendant(@p_last_child_hid, NULL);
       END          
      BEGIN 
      BEGIN TRY
        BEGIN TRAN 
             --SET @t_hid = HIERARCHYID::GetRoot();
             SET @t_hid = hierarchyid::GetRoot().GetDescendant(NULL,NULL);
             INSERT INTO dbo.Projects(p_code, p_hid, p_name,p_startdate, p_finishdate)
              VALUES(@p_code, @p_hid, @p_name, @p_startdate, @p_finishdate)
             SET @Identity =  SCOPE_IDENTITY();            
             INSERT INTO dbo.Tasks(p_id, t_name, t_hid, t_startdate, t_finishdate,t_state)
             VALUES(@Identity, @p_name, @t_hid , @p_startdate, @p_finishdate, 0)              
        COMMIT TRAN
       END TRY       
   BEGIN CATCH
      IF @@TRANCOUNT > 0
        ROLLBACK TRAN
       RAISERROR ('Attempt to insert value in  Project or Tasks Tables',16,1)
   END CATCH     
   END
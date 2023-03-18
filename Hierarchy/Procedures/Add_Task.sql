USE PMSHierarchyDB;
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC dbo.Add_Task
  @p_id AS INT, @t_mgrid AS INT,  
  @t_name AS VARCHAR(25)= 'sub task 1', 
  @t_startdate AS DATE = '2008-01-01', @t_finishdate AS DATE ='2008-12-31',
  @t_state AS INT = 0

AS  
     DECLARE  @t_hid AS HIERARCHYID, @t_mgr_hid AS HIERARCHYID,
              @t_last_child_hid AS HIERARCHYID
          
   BEGIN               
        SET @t_mgr_hid = (SELECT t_hid FROM dbo.Tasks WHERE t_id = @t_mgrid and p_id = @p_id);  
        SET @t_last_child_hid =
        (SELECT MAX(t_hid) FROM dbo.Tasks
         WHERE t_hid.GetAncestor(1) = @t_mgr_hid); 
         SET @t_hid = @t_mgr_hid.GetDescendant(@t_last_child_hid, NULL);
   END 
       
   BEGIN 
      BEGIN TRY
        BEGIN TRAN                     
             INSERT INTO dbo.Tasks(p_id, t_name, t_hid, t_startdate, t_finishdate,t_state)
             VALUES(@p_id, @t_name, @t_hid, @t_startdate, @t_finishdate, 0)              
        COMMIT TRAN
       END TRY       
       BEGIN CATCH
      IF @@TRANCOUNT > 0
        ROLLBACK TRAN
       RAISERROR ('Attempt to insert value in "Tasks" Table',16,1)
       END CATCH     
  END
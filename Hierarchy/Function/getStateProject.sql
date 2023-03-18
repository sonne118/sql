USE PMSHierarchyDB;
GO
CREATE FUNCTION dbo.getStateProject (@p_id INT)
RETURNS int
WITH EXECUTE AS CALLER
AS
BEGIN      
    DECLARE @state AS INT;   
       
       WITH StateCTE AS
        (                          
            SELECT p_id , p_hid, p_lvl        
            FROM dbo.Projects                       
            WHERE p_id = @p_id                 
            UNION ALL           
            SELECT p.p_id, p.p_hid, p.p_lvl  
            FROM StateCTE AS s
            JOIN dbo.Projects as p
            ON p.p_hid.GetAncestor(1) = s.p_hid                         
        )        
       
       SELECT  
       @state = (CASE WHEN s.Completed >= 0 AND  s.inProcess = 0 AND s.Planned = 0 THEN 1 
          WHEN s.Completed >= 0  AND  s.inProcess > 0 AND s.Planned = 0 THEN 0 
          WHEN s.Completed >= 0 AND  s.inProcess >= 0 AND s.Planned > 0 THEN -1 ELSE NULL END )
        FROM(
        SELECT  
         COUNT(CASE WHEN t.t_state = 0 then 1 ELSE NULL END) as inProcess,
         COUNT(CASE WHEN t.t_state = 1 then 1 ELSE NULL END) as "Completed",
         COUNT(CASE WHEN t.t_state = -1 then 1 ELSE NULL END) as "Planned"                
        FROM (SELECT 
            t.t_id,
            t.t_state
              FROM StateCTE AS s
              LEFT JOIN dbo.Tasks AS t
              ON s.p_id = t.p_id) AS t) AS s

        RETURN @state
END;
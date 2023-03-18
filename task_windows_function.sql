DECLARE @Timecards TABLE(	
		ID int Identity(1,1),	
		BusinessDate smalldatetime ,
		StartDate datetime ,
		EndDate datetime,
		EmployeeID uniqueidentifier  	
)
DECLARE @BreakRules TABLE(	
	ID int Identity(1,1),	
	MinBreakMinutes int  ,
	BreakRequiredAfter  decimal(10,2) ,
	TakeBreakWithin  decimal(10,2) 
)

-- fill timecards
DECLARE @EmployeeID uniqueidentifier 
DECLARE @BusinessDate smalldatetime

SET @EmployeeID =newid()
set @BusinessDate ='2/28/2023'
INSERT INTO  @Timecards (EmployeeID, BusinessDate,	StartDate,	EndDate)
Values(@EmployeeID, @BusinessDate,'2/28/2023 5:55','2/28/2023 9:24')
INSERT INTO  @Timecards (EmployeeID, BusinessDate,	StartDate,	EndDate)
Values(@EmployeeID, @BusinessDate,'2/28/2023 9:55','2/28/2023 16:18')
--Values(@EmployeeID, @BusinessDate,'2/28/2023 9:50','2/28/2023 16:18')
set @BusinessDate= '2/27/2023'
INSERT INTO  @Timecards (EmployeeID, BusinessDate,	StartDate,	EndDate)
Values(@EmployeeID, @BusinessDate,'2/27/2023 6:00','2/27/2023 17:20')
--Values(@EmployeeID, @BusinessDate,'2/27/2023 6:00','2/27/2023 19:20')
SET @EmployeeID =newid()
set @BusinessDate ='2/28/2023'
INSERT INTO  @Timecards (EmployeeID, BusinessDate,	StartDate,	EndDate)
Values(@EmployeeID, @BusinessDate,'2/28/2023 5:20','2/28/2023 8:30')
INSERT INTO  @Timecards (EmployeeID, BusinessDate,	StartDate,	EndDate)
Values(@EmployeeID, @BusinessDate,'2/28/2023 8:45','2/28/2023 13:03')
INSERT INTO  @Timecards (EmployeeID, BusinessDate,	StartDate,	EndDate)
Values(@EmployeeID, @BusinessDate,'2/28/2023 13:33','2/28/2023 17:00')
--Values(@EmployeeID, @BusinessDate,'2/28/2023 13:15','2/28/2023 17:00')
INSERT INTO  @Timecards (EmployeeID, BusinessDate,	StartDate,	EndDate)
Values(@EmployeeID, @BusinessDate,'2/28/2023 17:25','2/28/2023 19:00')

-- fill rules
INSERT INTO @BreakRules (MinBreakMinutes ,	BreakRequiredAfter   ,	TakeBreakWithin)
Values(30,6,5)
INSERT INTO @BreakRules (MinBreakMinutes ,	BreakRequiredAfter   ,	TakeBreakWithin)
Values(30,9,9)
INSERT INTO @BreakRules (MinBreakMinutes ,	BreakRequiredAfter   ,	TakeBreakWithin)
Values(30,12,11)


-------------------------------------query to run------------------------------------------------------------------------------------

;WITH cte AS   --using CTE approach of writing sql script in more structural view. It do not influence on performance.
  (
   SELECT  EmployeeID, BusinessDate, StartDate,EndDate, SUM_WORK_MINUTES, START_TIME_WORK,
   SUM(REST_WITH_SHIFT_MINUTES) OVER(PARTITION BY EmployeeID, BusinessDate ORDER BY StartDate)  AS REST_SUM  --the sum of increasing rest of worker during the day in minutes. It was necessery done in derived tables due to restric windows function
       FROM
		  (SELECT EmployeeID, BusinessDate, StartDate,EndDate, 		 
		   ISNULL(DATEDIFF(MINUTE, LAG(EndDate) OVER(PARTITION BY EmployeeID, BusinessDate ORDER BY StartDate), StartDate),0) AS REST_WITH_SHIFT_MINUTES,   --offset(shift) data of rest of workers  		   
		   SUM(DATEDIFF(MINUTE,StartDate,EndDate)) OVER(PARTITION BY EmployeeID, BusinessDate) AS SUM_WORK_MINUTES, --the sum of increasing hours of work in minutes
		   FIRST_VALUE(StartDate) OVER(PARTITION BY EmployeeID, BusinessDate ORDER BY StartDate,EndDate ) AS START_TIME_WORK  -- the first point of start work for tracking of consistency of rules
		   FROM @Timecards) AS q
 )

SELECT EmployeeID, BusinessDate, COUNT(r.ID) AS NumberOfNotSatisfiedRules
FROM cte t
OUTER APPLY  -- using outer apply to exclude unnnesesery lines
   (SELECT *
   FROM @BreakRules
   WHERE  BreakRequiredAfter*60  < (t.SUM_WORK_MINUTES + REST_SUM) AND  DATEADD(HOUR,TakeBreakWithin, t.START_TIME_WORK) < t.EndDate  AND MinBreakMinutes >  t.REST_SUM ) as r -- main logic of task
   -- conditions are perfomed between BreakRequiredAfter and a sums of increasing minutes of work in conjunction with sums of increasing rest of worker
   -- then being compared rolling calculations "TakeBreakWithin" with static start point of work and end point time("EndData") of current shift of worker
   -- when is shown current  shift hasn't finish yet and condition is true
   -- and then is perfomed conditions that whether minutes of rest enough or not. There are between data of current rule "MinBreakMinutes"  and rolling calculations"REST_SUM" minutes of rest of worker
   GROUP BY t.EmployeeID, t.BusinessDate  --grouping data  to output the necessery data for task result


--------------------------------query for debugging---------------------------------------------------------------------------------------
;WITH cte AS --using CTE approach of writing sql script in more structural view. It do not influence on performance.
  (
   SELECT * ,
   SUM(REST_WITH_SHIFT_MINUTES) OVER(PARTITION BY EmployeeID, BusinessDate ORDER BY StartDate)  AS REST_SUM   --the sum of increasing rest of worker during the day in minutes. It was necessery done in derived tables due to restric windows function
       FROM
		  (SELECT *, 	 		   
		   ISNULL(DATEDIFF(MINUTE, LAG(EndDate) OVER(PARTITION BY EmployeeID, BusinessDate ORDER BY StartDate), StartDate),0) AS REST_WITH_SHIFT_MINUTES,  --offset(shift) data of rest of workers 
		   ISNULL(DATEDIFF(MINUTE, EndDate, LEAD(StartDate) OVER(PARTITION BY EmployeeID, BusinessDate ORDER BY StartDate)),0)  AS REST_WITHOUT_SHIFT_MINUTES, --rest of worker after current shift for researching task
		   SUM(DATEDIFF(HOUR,StartDate,EndDate)) OVER(PARTITION BY EmployeeID, BusinessDate ORDER BY StartDate,EndDate )AS SUM_WORK_HOUR , --the sum of increasing hours of work in hours for researching
		   SUM(DATEDIFF(MINUTE,StartDate,EndDate)) OVER(PARTITION BY EmployeeID, BusinessDate ORDER BY StartDate,EndDate ) AS SUM_WORK_MINUTES, --the sum of increasing minutes of work in minutes
		   FIRST_VALUE(StartDate) OVER(PARTITION BY EmployeeID, BusinessDate ORDER BY StartDate,EndDate ) AS START_TIME_WORK -- the first point of start work for tracking of consistency of rules
		   FROM @Timecards) AS q
 )

SELECT *, DATEADD(HOUR,TakeBreakWithin, t.START_TIME_WORK) AS  TAKE_BREAK_WITHIN_TIME 
FROM cte t
OUTER APPLY  -- using cross apply to show all lines for researching task
   (SELECT *
   FROM @BreakRules
   WHERE  BreakRequiredAfter*60   < (t.SUM_WORK_MINUTES + REST_SUM) AND  DATEADD(HOUR,TakeBreakWithin, t.START_TIME_WORK) < t.EndDate  AND MinBreakMinutes >  t.REST_SUM) as r   -- main logic of task
   -- conditions are perfomed between BreakRequiredAfter and a sums of increasing minutes of work in conjunction with sums of increasing rest of worker
   -- then being compared rolling calculations "TakeBreakWithin" with static start point of work and end point time("EndData") of current shift of worker
   -- when is shown current  shift hasn't finish yet and condition is true
   -- and then is perfomed conditions that whether minutes of rest enough or not. There are between data of current rule "MinBreakMinutes"  and rolling calculations"REST_SUM" minutes of rest of worker
   
------------------------------------------------------------------------------------------------------------------------

SELECT *
FROM @BreakRules

-------------------------------------------------------------------------------------------------------------------------








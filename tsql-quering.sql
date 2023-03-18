--------------------------------------------------------

SELECT  orderid
      ,custid
      ,empid
      ,orderdate       
  FROM [TSQL2012].[Sales].[Orders]
  WHERE  orderdate = (SELECT TOP(1) orderdate
                 FROM [Sales].[Orders] 
			     ORDER BY orderdate DESC                 
                 )

SELECT  orderid
      ,custid
      ,empid
      ,orderdate       
  FROM [TSQL2012].[Sales].[Orders]
  WHERE  orderdate = (SELECT  MAX(orderdate)
                 FROM [Sales].[Orders] )

--------------------------------------------------------
SELECT orderid
      ,custid
	  ,orderdate
      ,empid             
  FROM Sales.Orders
  WHERE custid IN ( SELECT TOP(1) WITH TIES custid
        FROM [Sales].Orders  
	    GROUP BY custid
		ORDER BY COUNT(*) DESC); 


-------------------------------------------------------

SELECT 
  empid,
  firstname
 FROM HR.Employees
 WHERE empid  NOT IN (SELECT empid
                 FROM Sales.Orders
				 WHERE orderdate >= '20080501')


-------------------------------------------------------

SELECT 
--DISTINCT country -- without GROUP BY
  country
FROM Sales.Customers AS c
WHERE  NOT EXISTS (SELECT * FROM HR.Employees  AS e
                   WHERE e.country = c.country)
GROUP BY country
--------

SELECT 
DISTINCT country
FROM Sales.Customers 
WHERE  country NOT IN (SELECT e.country FROM HR.Employees  AS e)

-------------------------------------------------------

SELECT 
c.custid, c.orderid, c.orderdate, empid
FROM Sales.Orders AS c
WHERE orderdate =(SELECT MAX(orderdate) 
                  FROM Sales.Orders AS o
                  WHERE o.custid  = c.custid)
ORDER BY  c.custid

-----------------------------------------------------

SELECT
custid, companyname
FROM Sales.Customers AS c
WHERE  c.custid IN (SELECT custid FROM Sales.Orders
                   WHERE orderdate BETWEEN '20070101' AND '20080101')
	 AND c.custid NOT IN (SELECT custid FROM Sales.Orders
                   WHERE orderdate BETWEEN '20080101' AND '20090101')

SELECT
custid, companyname
FROM Sales.Customers AS c
WHERE  EXISTS (SELECT custid FROM Sales.Orders
                   WHERE orderdate BETWEEN '20070101' AND '20080101'
				   AND c.custid = custid)
	 AND NOT EXISTS (SELECT custid FROM Sales.Orders
                   WHERE orderdate BETWEEN '20080101' AND '20090101'
				   AND c.custid = custid)


-----------------------------------------------------
SELECT custid, companyname
FROM Sales.Customers
WHERE custid IN (SELECT custid
                 FROM Sales.Orders AS o
                 WHERE EXISTS (SELECT * FROM Sales.OrderDetails AS d  --Sales.Orders
                 WHERE productid = 12 
			     AND d.orderid = o.orderid))

SELECT custid, companyname
FROM Sales.Customers AS c 
WHERE EXISTS  (SELECT custid
                 FROM Sales.Orders AS o
                 WHERE o.custid = c.custid AND  EXISTS (SELECT * FROM Sales.OrderDetails AS d  --Sales.Orders
                 WHERE productid = 12 
			     AND d.orderid = o.orderid))

-----------------------------------------------------

SELECT custid,ordermonth, qty,
(SELECT SUM(qty) FROM Sales.CustOrders AS o2
                 WHERE  o1.custid = o2.custid AND o1.ordermonth >= o2.ordermonth ) AS runqty
FROM Sales.CustOrders AS o1
ORDER BY custid, ordermonth

SELECT orderid, orderdate, empid, custid,
 (SELECT MAX(o2.orderid) FROM Sales.Orders AS o2
      WHERE o2.orderid < o1.orderid) AS nextmonth
FROM Sales.Orders AS o1

SELECT orderid, orderdate, empid, custid,
 (SELECT MIN(o2.orderid) FROM Sales.Orders AS o2
      WHERE o2.orderid > o1.orderid) AS nextmonth
FROM Sales.Orders AS o1



----------------------------------------------------


SELECT 
empid, MAX(orderdate) AS maxOrdeDate
FROM Sales.Orders
GROUP BY empid 


----------------------------------------------

SET STATISTICS IO ON;
SET NOCOUNT ON;
GO
SELECT O.empid, O.orderdate, O.orderid, O.custid
FROM Sales.Orders AS O
JOIN (SELECT 
empid, MAX(orderdate) AS maxOrdeDate
FROM Sales.Orders
GROUP BY empid) AS D
ON D.empid = O.empid AND  D.maxOrdeDate = O.orderdate

------------------------------------------------


SELECT orderid, orderdate, custid, empid,
ROW_NUMBER() OVER(ORDER BY orderdate,  orderid  ) AS rownum
FROM Sales.Orders

------------------------------------------------

WITH  rowCTE AS
(
SELECT orderid, orderdate, custid, empid,
ROW_NUMBER() OVER(ORDER BY orderdate,  orderid  ) AS rownum
FROM Sales.Orders
)

SELECT * FROM  rowCTE
WHERE rownum BETWEEN 11 AND 20
--ORDER BY orderdate,  orderid
--OFFSET 10 ROWS FETCH FIRST 10 ROWS ONLY;  

-------------------------------------------------

WITH chainCTE AS
(

SELECT empid, mgrid, firstname, lastname
FROM HR.Employees
WHERE empid = 9
UNION ALL
SELECT C.empid, C.mgrid, C.firstname, C.lastname
FROM chainCTE AS P
 JOIN HR.Employees AS C 
 ON P.mgrid = C.empid
)

SELECT empid, mgrid, firstname, lastname
FROM chainCTE

----------------------------------------------

USE TSQL2012
IF OBJECT_ID('Sales.VEmpOrders') IS NOT NULL
  DROP VIEW Sales.VEmpOrders;
  GO

CREATE VIEW Sales.VEmpOrders 

AS
SELECT empid, YEAR(orderdate) AS orderyear, SUM(D.qty) AS qty
FROM Sales.Orders AS O
JOIN Sales.OrderDetails  AS D
ON O.orderid = D.orderid
 GROUP BY empid, YEAR(orderdate)
GO

SELECT * FROM Sales.VEmpOrders
ORDER BY  empid, orderyear

--ALTER VIEW Sales.VEmpOrders 

---------------------------------------------

SELECT empid, orderyear, qty,
SUM(qty) OVER(PARTITION BY empid ORDER BY orderyear) AS runqty
FROM Sales.VEmpOrders
ORDER BY  empid, orderyear

-----same result-----------
SELECT empid, orderyear, qty,
 (SELECT SUM(qty) FROM Sales.VEmpOrders AS v2
      WHERE v2.empid = v1.empid AND v2.orderyear <= v1.orderyear) AS runqty
	  FROM Sales.VEmpOrders as v1
ORDER BY  empid, orderyear

----------------------------------------------

USE TSQL2012
IF OBJECT_ID('Production.TopProduct') IS NOT NULL
DROP FUNCTION Production.TopProduct;
GO

CREATE FUNCTION Production.TopProduct
(@supid AS INT, @n AS INT) RETURNS TABLE

AS
RETURN
SELECT TOP(@n) productid, productname, unitprice 
FROM Production.Products
WHERE supplierid = @supid
ORDER BY unitprice DESC

/*
  -- With OFFSET-FETCH
  SELECT productid, productname, unitprice
  FROM Production.Products
  WHERE supplierid = @supid
  ORDER BY unitprice DESC
  OFFSET 0 ROWS FETCH NEXT @n ROWS ONLY;
  */

GO

SELECT * FROM Production.TopProduct(5,2)

----------------------------------------------
SELECT S.supplierid, S.companyname, P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  CROSS APPLY Production.TopProduct(S.supplierid, 2) AS P;


-------------------------------------------------------

 SELECT orderid, custid, val,
  SUM(val) OVER() AS totalvalue,
  SUM(val) OVER(PARTITION BY custid) AS custtotalvalue
FROM Sales.OrderValues;

---
SELECT empid, ordermonth, val,
  SUM(val) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;
---
SELECT empid, ordermonth, val,
  SUM(val) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN 2  PRECEDING
                AND 2 FOLLOWING) AS runval
FROM Sales.EmpOrders;

SELECT custid, [1], [2], [3]
FROM (SELECT empid, custid, qty
      FROM dbo.Orders) AS D
  PIVOT(SUM(qty) FOR empid IN([1], [2], [3])) AS P;

  -------------------------------------------------------------
   -----1------

   SELECT  *,
   RANK() OVER(PARTITION BY custid ORDER BY qty) AS drnk
   FROM dbo.Orders 

   -----2------------------------------------------------------

   SELECT  *,
   qty-LAG(qty) OVER(PARTITION BY custid ORDER BY qty) AS difnext,
   qty-LEAD(qty) OVER(PARTITION BY custid ORDER BY qty) AS diffprev
   FROM dbo.Orders 

   -----3-------------------------------------------------------

   -- Using standard solution
   SELECT empid,
  COUNT(CASE WHEN orderyear = 2014 THEN orderyear END) AS [2014],
  COUNT(CASE WHEN orderyear = 2015 THEN orderyear END) AS [2015],
  COUNT(CASE WHEN orderyear = 2016 THEN orderyear END) AS [2016]  
  FROM (SELECT empid, YEAR(orderdate) AS orderyear
      FROM dbo.Orders) AS D
  GROUP BY empid;
   
   ---first PIVOT solution
   SELECT  empid, [2014], [2015], [2016]
   FROM( SELECT empid,YEAR(orderdate) AS orderyear
      FROM dbo.Orders ) AS D
   PIVOT (COUNT(orderyear) FOR orderyear IN ([2014], [2015], [2016])) AS P

   ---second PIVOT solution
   SELECT  empid, [2014], [2015], [2016]
   FROM( SELECT empid,YEAR(orderdate) AS orderyear, orderid
      FROM dbo.Orders ) AS D
   PIVOT (COUNT(orderid) FOR orderyear IN ([2014], [2015], [2016])) AS P


   SELECT custid, [1], [2], [3]
   FROM (SELECT empid, custid, qty
      FROM dbo.Orders) AS D
  PIVOT(SUM(qty) FOR empid IN([1], [2], [3])) AS P;

   -------------------------------------------------------------- 

   DROP TABLE IF EXISTS dbo.EmpYearOrders;

	CREATE TABLE dbo.EmpYearOrders
	(
	  empid INT NOT NULL
		CONSTRAINT PK_EmpYearOrders PRIMARY KEY,
	  cnt2014 INT NULL,
	  cnt2015 INT NULL,
	  cnt2016 INT NULL
	);

	INSERT INTO dbo.EmpYearOrders(empid, cnt2014, cnt2015, cnt2016)
	  SELECT empid, [2014] AS [2014], [2015] AS [2015], [2016] AS [2016]
	  FROM (SELECT empid, YEAR(orderdate) AS orderyear
			FROM dbo.Orders) AS D
		PIVOT(COUNT(orderyear)
			  FOR orderyear IN([2014], [2015], [2016])) AS P;

	SELECT * FROM dbo.EmpYearOrders;

	 --------------------------------------------------------

	 SELECT empid, CAST(RIGHT(yearorder,4) AS INT), numorders
	 FROM dbo.EmpYearOrders
	 UNPIVOT (numorders FOR yearorder IN(cnt2014, cnt2015, cnt2016)) AS P
	 WHERE numorders <> 0








				   






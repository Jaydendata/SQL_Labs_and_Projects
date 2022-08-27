-- Lab: Paygap Dataset


--  1.	How many companies are in the data set?

SELECT DISTINCT employerid
FROM public.gender_pay_gap_21_22

-- 2.	How many of them submitted their data after the reporting deadline?

SELECT DISTINCT employerid
FROM public.gender_pay_gap_21_22
WHERE datesubmitted > duedate

-- 3.	How many companies have not provided a URL?

SELECT companylinktogpginfo
FROM public.gender_pay_gap_21_22
WHERE companylinktogpginfo NOT ILIKE '%HTTP%'
GROUP BY companylinktogpginfo

--- Found out that only ‘0’ values are presented other than website links.

SELECT COUNT(DISTINCT employerid) AS Num_no_address
FROM public.gender_pay_gap_21_22
WHERE companylinktogpginfo NOT ILIKE '%HTTP%'

--- Searched for entries with NULL or 0 values, and found 3,700 unique employer IDs without a web address.



-- 4.	Which measures of pay gap contain too much missing data, and should not be used in our analysis?

/* 
1)	Used the following codes to find out Null or 0 values in:
	Diffmeanhourlypercent
	Diffmedianhourlypercent
	Diffmeanbonuspercent
	Diffmedianbonuspercent
*/

SELECT
        SUM(CASE
        WHEN diffmeanhourlypercent in (NULL,0) THEN 1 ELSE 0 END) AS Zero_MeanHourPercent_Count
        ,SUM(CASE
        WHEN diffmedianhourlypercent in (NULL,0) THEN 1 ELSE 0 END) AS Zero_MedianHourPercent_Count
        ,SUM(CASE
        WHEN diffmeanbonuspercent in (NULL,0) THEN 1 ELSE 0 END) AS Zero_MeanBonusPercent_Count
        ,SUM(CASE
        WHEN diffmedianbonuspercent in (NULL,0) THEN 1 ELSE 0 END) AS Zero_MedianBonusPercent_Count
FROM public.gender_pay_gap_21_22

--- According to gov.uk’s guidance, a zero percentage is ‘highly unlikely’ for mean percentage differences, but could exist for median gender pay gaps. 



-- 2)	Found out the total counts of diffmeanbonuspercent and the total counts of zero-valued lines with the following Codes:

SELECT SUM(CASE
              WHEN diffmeanbonuspercent in (NULL,0) 
              THEN 1 ELSE 0 END
              )AS Zero_Values
       ,COUNT(diffmeanbonuspercent) AS Total_counts
FROM public.gender_pay_gap_21_22


-- 3)	Used the following codes to find out that the zero-valued entries is about 28% of the total entries. Therefore, the diffmeanbonuspercent column may not be used for comparison because of its relevant large 0 values. 

WITH counts AS(
SELECT SUM(CASE
              WHEN diffmeanbonuspercent in (NULL,0) 
              THEN 1 ELSE 0 END
              )AS Zero_Values
       ,COUNT(diffmeanbonuspercent) AS Total_counts
       
FROM public.gender_pay_gap_21_22)


SELECT ROUND(
            Zero_values/Total_counts::numeric,2
            )AS Percent_of_Zeros
FROM counts


/*
5.	Choose which column you will use to calculate the pay gap. Will you use DiffMeanHourlyPercent or DiffMedianHourlyPercent? Can you justify your choice?
Because the median only uses the middle one or two values, it is unaffected by extreme outliers. Median is usually a better value to use in terms of income measurements. This is because Even though it is no direction function for the median, we can still look at the maximum, minimum and mean value in these data. Used the following codes to find out max, min, and average values within DiffMeanHourlyPercent and DiffMedianHourlyPercent:
*/

SELECT max(diffmeanhourlypercent) AS meanmax
   	,min(diffmeanhourlypercent)AS meannmax
,ROUND(AVG(diffmeanhourlypercent),2)AS meanAVG
    	,max(diffmedianhourlypercent) AS medianmax
    	,min(diffmedianhourlypercent)AS medianmin
    	,ROUND(AVG(diffmedianhourlypercent),2)AS medianAVG
FROM public.gender_pay_gap_21_22

/* 
We can see that there is a dramatic difference (extreme values) between the minimum and maximum values in both mean and median hourly differences. The average value indicates that they are not in perfect nominal distribution, but possibly skewed. 
Therefore, the median value is a better fit for the analysis. 
*/



/*
6.	Use an appropriate metric to find the average gender pay gap across all the companies in the data set. Did you use the mean or the median as your averaging metric? Can you justify your choice?
As justified in the previous question, DiffMedianHourlyPercent is a better choice for the metric.
The metric is coded as following: 
*/

WITH Distinct_Employer_MedianGap
    AS(
        SELECT employerid
              ,AVG(diffmedianhourlypercent)AS Indv_Employer_MedianGap
        FROM public.gender_pay_gap_21_22
        WHERE diffmeanhourlypercent NOT IN (0,100)
              AND diffmeanbonuspercent NOT IN (0,100)
        GROUP BY 1
        ORDER BY 2 DESC)

SELECT AVG(Indv_Employer_MedianGap)AS AVG_Employer_MedianGap
FROM Distinct_Employer_MedianGap

/*
Entries with Null/Extreme values (0 or 100%) in the mean hourly differences are excluded.
Therefore, the average pay gap across all the individual companies is 12%, which means on average, male employees receive 12% more hourly pay than their female colleagues. 
*/

/*
7.	What are some caveats we need to be aware of when reporting the figure we’ve just calculated?

1)	This is a primitive analysis directly using the raw data stored in a database. Ideally, further analysis should be conducted for refined results with careful cleaning and organization of the data. 
2)	The conclusion is reached solely on the summary statistics such as the average, max and min values. The analysis did not include any visualization of key variables, which may give different insights into the big picture. 
3)	The conclusions reached so far are based on only a few columns from the whole table. Other columns might be worth examination using tools such as a pivot table for extended insights.
*/


/*
8.	What are the 10 companies with the largest pay gaps skewed towards men?
Based on the previous code, further add employerid, employername to the Indv_Employer_MedianGap results:
*/

SELECT DISTINCT employerid
       ,employername
       , ROUND(AVG(diffmedianhourlypercent),2)
        AS Indv_Employer_MedianGap
FROM public.gender_pay_gap_21_22
WHERE diffmeanhourlypercent NOT IN (0,100)
      AND diffmeanbonuspercent NOT IN (0,100)
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10

/*Entries with Null/Extreme values (0 or 100%) in the mean hourly differences are excluded.

employerid	employername	indv_employer_mediangap
11051	SERVICE INNOVATION GROUP-UK LIMITED	 90.40 
2321	BRAND ENERGY & INFRASTRUCTURE SERVICES UK, LTD.	 89.00 
8666	MOTORLINE LIMITED	 71.40 
9499	P. D. HOOK (GROUP) LIMITED	 69.00 
12525	THE PRACTICE SURGERIES LIMITED	 64.70 
21246	The BlueKite Trust	 64.30 
2831	CARE FERTILITY GROUP LIMITED	 64.00 
19782	INTIMATE APPAREL RETAIL UK LIMITED	 63.80 
4432	EASYJET AIRLINE COMPANY LIMITED	 63.60 
15334	Kirkland & Ellis International LLP	 62.70 
*/

/* 
9.	What do you notice about the results? Are these well-known companies?
Added some additional information to the search: 
*/

SELECT employerid
       ,employername
       ,siccodes
       ,employersize
       , ROUND(AVG(diffmedianhourlypercent),2)
        AS Indv_Employer_MedianGap
FROM public.gender_pay_gap_21_22
WHERE diffmeanhourlypercent NOT IN (0,100)
      AND diffmeanbonuspercent NOT IN (0,100)
GROUP BY 4,1,2,3
ORDER BY 5 DESC
LIMIT 10

/* Results:
employerid	employername	siccodes	employersize	indv_employer
_mediangap	Public Company	>15 Ys History	Medium / Large Size
11051	SERVICE INNOVATION GROUP-UK LIMITED	82990	250 to 499	 90.40 		Y	
2321	BRAND ENERGY & INFRASTRUCTURE SERVICES UK, LTD.	96090	1000 to 4999	 89.00 		Y	Y
8666	MOTORLINE LIMITED	82990	500 to 999	 71.40 		Y	Y
9499	P. D. HOOK (GROUP) LIMITED	70100	Less than 250	 69.00 		Y	
12525	THE PRACTICE SURGERIES LIMITED	86210	500 to 999	 64.70 			Y
21246	The BlueKite Academy Trust	0	250 to 499	 64.30 			
2831	CARE FERTILITY GROUP LIMITED	86101,
86220,
86900	250 to 499	 64.00 		Y	
19782	INTIMATE APPAREL RETAIL UK LIMITED	47710	250 to 499	 63.80 			
4432	EASYJET AIRLINE COMPANY LIMITED	51101	5000 to 19,999	 63.60 		Y	Y
15334	Kirkland & Ellis International LLP	69102	500 to 999	 62.70 			Y

*The additional columns of information were added to each company by searching from the UK government’s company information website (link). 

The above table defines ‘Well-known’ by three criteria: 
1)	whether it is publicly listed, 
2)	established with a long history (over 15 years), or 
3)	in large size (over 500 as a medium company, and over 5,000 as a large company) 

From the table, we can conclude that:
a)	The top 10 are all private companies with limited liability, and no need to satisfy stock market shareholders.
b)	More than half of them (6 out of 10) have a long history of over 15 years.
c)	Half of them are medium or large size companies with over 500 staff members.

*/

/*
10.	Apply some additional filtering to pick out the most significant companies with large pay gaps.
1)	Check categories in employersize column
*/

SELECT DISTINCT employersize
       ,COUNT(employerid)
FROM public.gender_pay_gap_21_22
GROUP BY 1
ORDER BY 1

-- 2)	Using the previous coding, added condition to filter out only large organizations with employees of 5,000 or more.

SELECT employerid
       ,employername
       ,siccodes
       ,employersize
       ,ROUND(AVG(diffmedianhourlypercent),2)AS Indv_Employer_MedianGap
FROM public.gender_pay_gap_21_22
WHERE diffmeanhourlypercent NOT IN (0,100)
      AND diffmeanbonuspercent NOT IN (0,100)
      AND employersize IN ('5000 to 19,999','20,000 or more')
GROUP BY 1,2,3,4
ORDER BY 5 DESC
LIMIT 10

/*
The output is as following table, shows the top 10 very large organisations with significant pay gaps that skew to male over female employees.
employerid	employername	siccodes	employersize	indv_employer_mediangap
4432	EASYJET AIRLINE COMPANY LIMITED	51101	5000 to 19,999	       63.60 
6576	INDEPENDENT VETCARE LIMITED	75000	5000 to 19,999	       49.40 
3842	CVS (UK) LIMITED	75000	5000 to 19,999	       42.90 
5821	H&M HENNES & MAURITZ UK LIMITED	47710	5000 to 19,999	       42.60 
654	SAVILLS (UK) LIMITED	68310,
68320	5000 to 19,999	       41.10 
19265	VETPARTNERS PRACTICES LIMITED	75000	5000 to 19,999	       41.00 
7727	LLOYDS BANK PLC	64191	20,000 or more	       40.90 
15650	STONEGATE PUB COMPANY LIMITED	0	5000 to 19,999	       39.20 
3309	CIVICA UK LIMITED	62090	5000 to 19,999	       36.50 
4479	EDF ENERGY LIMITED	35110	5000 to 19,999	       36.30 
*/

/*
11.	How would you report on the results? Can we say that these companies are engaging in unlawful pay discrimination?
The primitive analysis does indicate a strongly skewed pay gap (favours males) in these very large organisations. However, the summary statistics does not indicate any correlation or causation between the numbers. 
It will be worthwhile to examine their industries before reaching any conclusion about pay discrimination, as some may employ very few females. For example, it is reasonable to assume that male pilots in the airline industry (EASYJET) will enjoy much higher pay compared to female flight attendants.  
*/

/*
12.	What’s the average pay gap in London versus outside London?
To compare the pay gap between regions, the code was revised to address addresses and postcodes.
*/

WITH In_London AS(
SELECT 
      ROUND(AVG(diffmedianhourlypercent),2)AS AVG_out_in_London
FROM public.gender_pay_gap_21_22  
WHERE diffmeanhourlypercent NOT IN (0,100)
      AND diffmeanbonuspercent NOT IN (0,100)
      AND address ILIKE('%London%'))   

SELECT *
FROM In_London

UNION

SELECT 
      ROUND(AVG(diffmedianhourlypercent),2)AS avg_out_in_London
FROM public.gender_pay_gap_21_22  
WHERE diffmeanhourlypercent NOT IN (0,100)
      AND diffmeanbonuspercent NOT IN (0,100)
      AND address NOT ILIKE('%London%')

/* 
Entries with Null/Extreme values (0 or 100%) in the mean hourly differences are excluded.
The upper value (11.06) represents the average percentage difference in the median hourly rate Outside of London, which is 3.8% lower than that In London (14.86).
*/
 
/*
13.	What’s the average pay gap in London versus Birmingham?
Used another way (CASE function) to identify locations:
*/

WITH Avg_Bri_Lon AS(
SELECT  employerid
        ,diffmedianhourlypercent
        ,CASE 
            WHEN diffmeanhourlypercent NOT IN (0,100)
                 AND diffmeanbonuspercent NOT IN (0,100)
                 AND address ILIKE('%London%')
            THEN 1
            ELSE 0
            END AS in_London
       ,CASE 
            WHEN diffmeanhourlypercent NOT IN (0,100)
                 AND diffmeanbonuspercent NOT IN (0,100)
                 AND address ILIKE('%Birmingham%')
            THEN 1
            ELSE 0
            END AS in_Birmingham
FROM public.gender_pay_gap_21_22)


SELECT ROUND(AVG(diffmedianhourlypercent),2) AS Avg_Bri_vs_Lon
       FROM Avg_Bri_Lon
where diffmedianhourlypercent IN
(SELECT diffmedianhourlypercent FROM Avg_Bri_Lon WHERE in_london =1) 

UNION

SELECT ROUND(AVG(diffmedianhourlypercent),2)
       FROM Avg_Bri_Lon
where diffmedianhourlypercent IN
(SELECT diffmedianhourlypercent FROM Avg_Bri_Lon WHERE in_Birmingham =1)

/*
Entries with Null/Extreme values (0 or 100%) in the mean hourly differences are excluded.
This will produce the following indicates that London’s average median pay gap is 12.43% against Brimingham’s 8.62%.
*/


/*
14.	What is the average pay gap within schools?
According to the Standard Industrial Classification (SIC) codes Guide (link), education organisations have SIC codes that begin with two numbers ‘85’. The following coding is used to extract answers:
*/

SELECT ROUND(AVG(diffmedianhourlypercent),2)
FROM public.gender_pay_gap_21_22      
WHERE LEFT(siccodes,2) = '85'
      AND diffmeanhourlypercent NOT IN (0,100)
      AND diffmeanbonuspercent NOT IN (0,100)

/*
Entries with Null/Extreme values (0 or 100%) in the mean hourly differences are excluded.
The result indicates that the average median in the pay gap is 17.34%, skewed to males.
*/


/*
15.	What is the average pay gap within banks?
According to the Standard Industrial Classification (SIC) codes Guide (link), banks have SIC codes ‘64110’ and ‘64191’. The following coding is used to extract answers:
*/

SELECT ROUND(AVG(diffmedianhourlypercent),2)
FROM public.gender_pay_gap_21_22      
WHERE siccodes LIKE'64110%' 
      OR siccodes LIKE'64191%'
      AND diffmeanhourlypercent NOT IN (0,100)
      AND diffmeanbonuspercent NOT IN (0,100)

/* 
Entries with Null/Extreme values (0 or 100%) in the mean hourly differences are excluded.
The result shows that the average median in the pay gap is 31.40%, skewed to males.
*/

/*
16.	Is there a relationship between the number of employees at a company and the average pay gap?
Examining the exact relationship will require the use of excel or other analytical tools. The following SQL codes prepare the information needed for further analysis. 
*/

SELECT ROUND(AVG(diffmedianhourlypercent),2)AS avg_median_gap
       ,employersize
FROM public.gender_pay_gap_21_22      
WHERE diffmeanhourlypercent NOT IN (0,100)
      AND diffmeanbonuspercent NOT IN (0,100)
      AND diffmedianhourlypercent>50
GROUP BY 2
ORDER BY 1 DESC

/*Entries with Null/Extreme values (0 or 100%) in the mean hourly differences are excluded.
The codes produced the following table:

avg_median_gap	employersize
63.60	5000 to 19,999
57.93	500 to 999
56.60	Less than 250
56.45	250 to 499
56.42	1000 to 4999
55.65	Not Provided

This implies there could be a potential relationship between the average median pay gap and the size of an organisation. 
*/
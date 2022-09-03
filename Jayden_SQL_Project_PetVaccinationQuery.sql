"""

Using a database named 'Animal_Shelter' to finish a following tasks.
The database contains 9 tables each have some columns regarding a dog/cat's information.


1. Joins

The task:
    Write a query to report animals and their vaccinations.
    Inlcude the animals that have not been vaccinated.
    The report should show the animal's:
    name, 
    species,
    breed, 
    primary color,
    vaccine name, 
    the staff member's first name, 
    last name, and 
    role.

"""
-- Need to use three tables: Animals, Vaccinations and Persons
--- First list out all Inner Joins and then other parts

SELECT 
    A.Name
    ,A.Species
    ,A.Breed
    ,A.Primary_Color
    ,V.Vaccination_Time
    ,V.Vaccine
    ,P.First_Name
    ,P.Last_Name
    ,S.Role
FROM Animals AS A 
    INNER JOIN
    Vaccinations AS V
        ON A.Name = V.Name AND A.Species = V.Species
    INNER JOIN 
    Staff_Assignments AS S
        ON V.Email = S.Email
    INNER JOIN 
    Persons AS P
        ON V.Email = P.Email;

--- But this only shows the animals (95 Rows) which are vaccinated.
--- to show all animals, need to left out join A and V. 
--- This won't work without quoting the remaining joins to regulate the execution order.

SELECT 
    A.Name
    ,A.Species
    ,A.Breed
    ,A.Primary_Color
    ,V.Vaccination_Time
    ,V.Vaccine
    ,P.First_Name
    ,P.Last_Name
    ,S.Role
FROM Animals AS A 
    LEFT OUTER JOIN
(
    Vaccinations AS V
    INNER JOIN 
    Staff_Assignments AS S
        ON V.Email = S.Email
    INNER JOIN 
    Persons AS P
        ON S.Email = P.Email
)
    ON A.Name = V.Name 
    AND 
    A.Species = V.Species;

--- Without the quotation, later INNER JOIN will override previous OUTER JOIN and reduce the rows again.
--- With the quotation, it show 149 rows affected including some Vaccine as NULL

"""

2. Filtering and Grouping considering NULL values


Write a query to report the number of vaccinations each animal has received.
Include animals that have never been vaccinated. 

Exclude rabbits, rabies vaccines, and animals that were last vaccinated on or after 01/10/2019.
The report should show:
    the animals name,
    species,
    primary color,
    breed, and
    the number of vaccinations. 

Use the correct logical join types and force order if needed. 
Use the correct logical group by expressions. 

"""

--- First, create dummy aggregates in order to comply with grouping rules
--- Also test out different COUNT() result:

SELECT 
    A.Name
    ,A.Species
    ,MAX(A.Primary_Color) AS Primary_Color
    ,MAX(A.Breed) AS Breed 
    -- Created Dummy Aggregate to avoid Group By error, the other way is to Group each of them
    ,COUNT(V.Vaccine) AS VaxCount, COUNT(*) AS AllCount -- Check if there's a difference between the two counts
FROM Animals AS A 
    LEFT OUTER JOIN -- All animals both Vaccinated and NonVaccinated
    Vaccinations AS V
    ON A.Name = V.Name AND A.Species = V.Species
GROUP BY A.Species, A.Name
ORDER BY A.Species, A.Name;

--- COUNT(*) will reply counts even when not vaccinated.
--- So remove COUNT(*) and continue:

SELECT 
    A.Name
    ,A.Species
    ,MAX(A.Primary_Color) AS Primary_Color -- Created Dummy Aggregate
    ,MAX(A.Breed) AS Breed -- Created Dummy Aggregate
    ,COUNT(V.Vaccine) AS VaxCount
FROM Animals AS A 
    LEFT OUTER JOIN
    Vaccinations AS V
    ON A.Name = V.Name AND A.Species = V.Species
WHERE A.Species != 'Rabbit' 
    AND (V.Vaccine != 'Rabies' OR V.Vaccine IS NULL)
    --- to add only 'Vac != Rabies' is NOT ok for it does not return NULL
    --- Dealt with NULL, include them in return using 'OR...IS NULL'
GROUP BY A.Species, A.Name
ORDER BY A.Species, A.Name;


--- Then continue to deal with date range, again, need to include NULL:

SELECT 
    A.Name
    ,A.Species
    ,MAX(A.Primary_Color) AS Primary_Color -- Created Dummy Aggregate
    ,MAX(A.Breed) AS Breed -- Created Dummy Aggregate
    ,COUNT(V.Vaccine) AS VaxCount
FROM Animals AS A 
    LEFT OUTER JOIN
    Vaccinations AS V
    ON A.Name = V.Name AND A.Species = V.Species
WHERE A.Species != 'Rabbit' 
    AND (V.Vaccine != 'Rabies' OR V.Vaccine IS NULL)
    --- Here, if to add 'AND V.Vaccination_Time < '20191001' is not ok
    --- Because the task is to illminate the grouped animal, not the individual rows
GROUP BY A.Species, A.Name
    --- So, add the condition in with HAVING:
HAVING 
    MAX(V.Vaccination_Time) < '20191001'
    OR 
    MAX(V.Vaccination_Time) IS NULL
    --- Define inside GROUP max time criteria
    --- Again, deal with NULL, return them even they are NULL
ORDER BY A.Species, A.Name;



"""

3. Subqueries

3.1 Fee Discount

Show adoption rows including fees, 
Max fee ever paid,
and a thrid column shows the discount against Max fee.

"""

-- Created an independent query to show Max fee
SELECT MAX(Adoption_Fee)
FROM Adoptions

-- Use it as a subquery
-- This adds a new column of MaxFee (All 100) after the last 'Adoption_Fee' Column. 
SELECT *
    ,(
        SELECT MAX(Adoption_Fee)
        FROM Adoptions
        ) AS Max_Fee
FROM Adoptions;

-- Calculate discount using Discount% = (MaxFee - Adop.fee)*100/MaxFee
-- Has to include the same subquery (MaxFee) three times:

SELECT *
    ,(
        SELECT MAX(Adoption_Fee)
        FROM Adoptions
        ) AS Max_Fee
    ,(
        (
            (
                SELECT MAX(Adoption_Fee)
                FROM Adoptions
                ) - Adoption_Fee
            )*100/(
                SELECT MAX(Adoption_Fee)
                FROM Adoptions
                )
        ) AS Discount_Percent
FROM Adoptions;

"""

3.2

Find out the Max Fee for each type of animal

"""

-- The intuitive approach is to modified by adding WHERE clause in the subquery:

SELECT *
    ,(
        SELECT MAX(Adoption_Fee)
        FROM Adoptions
        WHERE Species = 'Dog'
        ) AS MaxFee
FROM Adoptions;

-- To add a automatic feature to the codes
-- We can set Species = the species name in the Outter Query table
-- Thus we need to denote Inner query source and Outter query source

SELECT *
    ,(
        SELECT MAX(Adoption_Fee)
        FROM Adoptions AS A2
        WHERE A2.Species = A1.Species
    ) AS Max_Fee
FROM Adoption AS A1;

-- This will show differentiated Max Fees in the Max_Fee column, according to A1's species name
-- This method replaces the approach to first first calcuate out each species Max fee, then use CASE to create a new column. 

"""

3.3

Show people who adopted at least one animal

"""

-- My first thought is to JOIN Persons table with Adoptions table:
-- (Forgot about the DISTINCT at first - one may adopt multiple animals)

SELECT DISTINCT P.*
FROM Persons AS P
    INNER JOIN Adoptions AS A
    ON A.Adopter_Email = P.Email;

-- I found another way to do this using EXISTS
-- Correlational subquery: WHERE EXISTS (Subquery)

SELECT *
FROM Persons AS P
WHERE EXISTS (
                SELECT 1
                FROM Adoptions AS A
                WHERE A.Adopter_Email = P.Email
                )

-- A third way to do this is to use subquery as a filter:
-- WHERE...IN

SELECT *
FROM Persons
WHERE Email IN (
                SELECT Adopter_Email 
                FROM Adoptions
                )

"""

3.4 Set Operator

Find animals that were never adopted

"""

-- The first method is Left exclusive join
-- A LEFT JOIN B ON...WHERE B.Key is NULL

"""

3.4 Set Operator

Find animals that were never adopted

"""

-- The first method is Left exclusive join
-- A LEFT JOIN B ON...WHERE B.Key is NULL

SELECT DISTINCT AN.Name, AN.Species 
FROM Animals AS AN
	LEFT JOIN
	Adoption AS AD
	ON AN.Email = AD.Email
WHERE AD.Email IS NULL
            



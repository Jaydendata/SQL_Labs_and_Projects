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

USE Animal_Shelter

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
--- to show all animals, need to left outter join A and V. 
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

--- First, create dummy aggregates in order to comply with grouping rules, can use MAX()
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
    --- Dealt with NULL, include them in return using >> 'OR...IS NULL' <<
GROUP BY A.Species, A.Name
ORDER BY A.Species, A.Name;


--- Then continue to deal with date range, again, need to include NULL with OR MAX(datestemp) IS NULL:

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

-- Simple Subquery:
-- Created an independent query to show Max fee
SELECT MAX(Adoption_Fee)
FROM Adoptions

-- Use it as a subquery
-- This adds a new column of MaxFee (All valued 100) after the last 'Adoption_Fee' Column. 
SELECT *
    ,(
        SELECT MAX(Adoption_Fee)
        FROM Adoptions
        ) AS Max_Fee
FROM Adoptions;


-- More complicated subqueries:
-- In addition to MaxFee, calculate discount using Discount% = (MaxFee - Adop.fee)*100/MaxFee
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

-- The intuitive approach is to modified by adding WHERE clause in the subquery for EACH species:

SELECT *
    ,(
        SELECT MAX(Adoption_Fee)
        FROM Adoptions
        WHERE Species = 'Dog' -- repeat for each species
        ) AS MaxFee
FROM Adoptions;

-- But this is too complicated. Need to add an automatic feature to the codes
-- We can set Species = the species name in the Outter Query table
-- Thus we need to denote INNER query source and OUTTER query source as A2 and A1

SELECT *
    ,(
        SELECT MAX(Adoption_Fee)
        FROM Adoptions AS A2
        WHERE A2.Species = A1.Species
    ) AS Max_Fee
FROM Adoptions AS A1;

-- ** This will show differentiated Max Fees in the Max_Fee column, according to A1's species name
-- This method replaces the approach to first first calcuate out each species Max fee, then use CASE to create a new column. 

"""

3.3

Show people who adopted at least one animal

"""

-- My first thought is to JOIN Persons table with Adoptions table:
-- (Forgot about the DISTINCT too - one may adopt multiple animals)

SELECT DISTINCT P.*
FROM Persons AS P
    INNER JOIN Adoptions AS A
    ON A.Adopter_Email = P.Email;

-- Found another way to do this using EXISTS
-- Correlational subquery: WHERE EXISTS (Subquery)

SELECT *
FROM Persons AS P
WHERE EXISTS (
                SELECT 1
                FROM Adoptions AS A
                WHERE A.Adopter_Email = P.Email
                )

-- A third way to do this is to use subquery as a filter
-- using WHERE...(NOT) IN

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

-- The first method is to use Left Exclusive Join

/* Structure: 
A LEFT (OUTER) JOIN B 
    ON A.Key = B.Key 
WHERE B.Key is NULL
*/

SELECT DISTINCT AN.Name, AN.Species 
FROM Animals AS AN
	LEFT OUTER JOIN
	Adoptions AS AD
	ON AN.Name = AD.Name
    AND
    AN.Species = AD.Species
WHERE AD.Name IS NULL

-- The second method is to use NOT EXISTS
-- This method does not need to contain DISTINCT

SELECT AN.Name, AN.Species 
FROM Animals AS AN
WHERE NOT EXISTS (
                    SELECT 1 -- random name, can be anything
                    FROM Adoptions AS AD
                    WHERE AN.Name = AD.Name
                    )

-- !! The most elegant method is to use EXCEPT

SELECT Name, Species
FROM Animals
EXCEPT
SELECT Name, Species
FROM Adoptions


"""

3.5 Show breeds that were never adopted

Multiple animal names can belong to same breed
None breed does exists as 'NULL'.

"""
-- The Left Outter Join / Not Exists methods won't work 
--- because they only return animals not adopted, rather than breed

-- The 'Not in' method works, but:
/* 
Must write WHERE...IS NOT NULL at the end of the subquery
Otherwise NOT IN (NULL) yields unknown, 
because not in unknown is unknown, no value returned
*/

SELECT DISTINCT AN1.Breed, AN1.Species
FROM Animals AS AN1
WHERE AN1.Breed NOT IN (
                    SELECT AN2.Breed
                    FROM Animals AS AN2 
                    INNER JOIN Adoptions AS AD
                    ON AN2.Name = AD.Name
                    AND
                    AN2.Species = AD.Species
                    WHERE AN2.Breed IS NOT NULL
                    )

-- Use EXCEPT is much easier, just bridge the total set with the adopted set using EXCEPT
-- From the animal table, deduce breeds appear in the adoption table

SELECT AN1.Breed
FROM Animals AS AN1
EXCEPT
SELECT AN2.Breed
FROM Animals AS AN2
    INNER JOIN
    Adoptions AS AD
    ON AN2.Name = AD.Name
    AND AN2.Species = AD.Species


"""

3.6 JOIN - show adopters who adopted 2 animals in 1 day

"""

-- 1) use SELF (INNER) JOIN the table with itself
-- This will produce a cross join matrix with Name1+Species1 cross Name2+Speices2

SELECT A1.Adopter_Email
    ,A1.Adoption_Date
    ,A1.Name AS Name1
    ,A1.Species AS Species1
    ,A2.Name AS Name2
    ,A1.Species AS Species2

FROM Adoptions AS A1
    INNER JOIN
    Adoptions AS A2
    ON A1.Adopter_Email = A2.Adopter_Email
    AND A1.Adoption_Date = A2.Adoption_Date
    AND A1.Name != A2.Name
ORDER BY A1.Adopter_Email, A1.Adoption_Date;

-- 2) But there is the problem of a name / species swap in two rows. We only need one row.
-- One solution is to change the evaluator to > instead of !=, so the extral row will be eliminated

SELECT A1.Adopter_Email
    ,A1.Adoption_Date
    ,A1.Name AS Name1
    ,A1.Species AS Species1
    ,A2.Name AS Name2
    ,A1.Species AS Species2

FROM Adoptions AS A1
    INNER JOIN
    Adoptions AS A2
    ON A1.Adopter_Email = A2.Adopter_Email
    AND A1.Adoption_Date = A2.Adoption_Date
    AND A1.Name > A2.Name
ORDER BY A1.Adopter_Email, A1.Adoption_Date;

-- 3) But, this will ignore the same name animal from a different species
/* 
First thought might be to add OR A1.Species > A2.Species

However, this does not make a difference because of OR
AND neither works for all because there are NAME > NAME but Species = Species
So need to add MULTIPLE conditions after JOIN ON

The solution is to add specifc conditions that 
    either name=name and species != species
    or name > or < name (but not !=)
*/

SELECT A1.Adopter_Email
    ,A1.Adoption_Date
    ,A1.Name AS Name1
    ,A1.Species AS Species1
    ,A2.Name AS Name2
    ,A1.Species AS Species2

FROM Adoptions AS A1
    INNER JOIN
    Adoptions AS A2
    ON A1.Adopter_Email = A2.Adopter_Email
    AND A1.Adoption_Date = A2.Adoption_Date
    AND (
            (A1.Name = A2.Name AND A1.Species != A2.Species) 
            OR
            (A1.Name > A2.Name)
        )
ORDER BY A1.Adopter_Email, A1.Adoption_Date;


"""
3.7 Lateral Joins

Show animals and their most recent 3 vaccination

"""

-- The following won't work because subqueries much use standlone table expression
--- V.Name = A.Name is not usually not allow 

SELECT A.Name
    ,A.Species
    ,A.Primary_Color
    ,A.Breed
    ,Last_Vaccinations
FROM Animals AS A
    CROSS JOIN
    (
        SELECT V.Vaccine
            ,V.Vaccination_Time            
        FROM Vaccinations AS V
        WHERE V.Name = A.Name
        AND V.Species = A.Species               
    ) AS Last_Vaccinations;

/*
Use newly introduced features:

Correlate columns between the OUTTER and INNTER (sub)queries
    PostgreSQL - partially support, using  ..JOIN LATERAL...ON TRUE
    SQL Server - use ...APPLY instead of ...JOIN, no need to ON...
*/

SELECT A.Name
    ,A.Species
    ,A.Primary_Color
    ,A.Breed
    ,Last_Vaccinations
FROM Animals AS A
    CROSS JOIN
    (
        SELECT V.Vaccine
            ,V.Vaccination_Time            
        FROM Vaccinations AS V
        WHERE V.Name = A.Name
        AND V.Species = A.Species               
    ) AS Last_Vaccinations;

"""
Using a database named 'Animal_Shelter' to finish a following tasks.
The database contains 9 tables each have some columns regarding a dog/cat's information.

1. Joins

The task:
    Write a query to report animals and their vaccinations.
    Inlcude the animals that have not been vaccinated.
    The report should show the animal's:
    name, species, breed and primary color,vaccine name, the staff member's first name, last name and role.
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
        ON V.Email = P.Email

--- But this only shows the animals (95 Rows) which are vaccinated.
--- to show all animals, need to left out join A and V.

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
    ON A.Name = V.Name AND A.Species = V.Species

--- this will show 149 rows affected with some Vaccine as NULL v

"""
2. Filtering and Grouping with DISTINCT

Write a query to report the number of vaccinations each animal has received.
Include animals that were never vaccinated. 

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


--- First, test counts

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
ORDER BY A.Species, A.Name

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
    --- to add only Vac != Rabies is NOT ok for it does not return NULL
    --- Dealt with NULL, include them in return using 'OR...IS NULL'
GROUP BY A.Species, A.Name
ORDER BY A.Species, A.Name


--- Then continue to deal with date range:


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
    --- To add 'AND V.Vaccination_Time < '20191001' is not ok
    --- Because the task is to illminate the grouped animal, not the individual rows
GROUP BY A.Species, A.Name
    --- So, add the condition in with HAVING:
HAVING 
    MAX(V.Vaccination_Time) < '20191001'
    OR 
    MAX(V.Vaccination_Time) IS NULL
    --- Define inside GROUP max time range
    --- Again, deal with NULL, return them instead of allowing ignorance
ORDER BY A.Species, A.Name





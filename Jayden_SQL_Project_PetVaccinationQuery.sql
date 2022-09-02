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

SELECT * 
FROM Animals AS A 
    INNER JOIN
    Vaccinations AS V
    




 -- Create a New Book Record -- 
 -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, o_status, author, publisher)
VALUES
	('978-1-60129-456-2','To Kill a Mockingbird', 'Classic', '6.00', 'yes', 'Harper Lee', 'J.B. Lippincott & Co.' );
        
SELECT *
FROM books;

-- Task 2: Update an Existing Member's Address

UPDATE members
SET memeber_address = '125 Main St'
WHERE member_id = 'C101';

SELECT * FROM members;


-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT *
FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT
    issued_emp_id,
    COUNT(*)
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1;


-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results 
-- each book and total book_issued_cnt**
CREATE TABLE book_cnt
AS
SELECT 
	b.isbn,
    book_title,
    COUNT(ist.issued_id) as Num_Issued
FROM books as b
JOIN issued_status as ist
ON ist.issued_book_isbn = b.isbn
GROUP BY 1, 2;

SELECT *
FROM book_cnt;


-- Task 7. Retrieve All Category of Books with Number of Books in every category:

SELECT 
	category,
    COUNT(*) AS total_books
FROM books
GROUP BY category;


-- Task 8. Retrieve All Books From "Classic" Category:

SELECT *
FROM books
WHERE category = 'Classic';

-- Task 9: Find Total Rental Income by Category:
SELECT 
	b.category,
    SUM(b.rental_price) AS Rent_By_Category,
    COUNT(*) AS Issued_Frequency
FROM books AS b
JOIN issued_status as ist
ON ist.issued_book_isbn = b.isbn
GROUP BY 1
ORDER BY SUM(b.rental_price) DESC;

-- TASK 10: List Members Who Registered in the Year 2021:
SELECT *
FROM members
WHERE YEAR(reg_date) = 2021;

-- TASK 11 List Employees with Their Branch Manager's Name and their branch details:

SELECT
	e1.emp_id,
    e1.emp_name,
    e1.emp_position,
    e1.*,
    e2.emp_name AS Manager
FROM employees AS e1
JOIN branch as b
ON e1.branch_id = b.branch_id
JOIN employees as e2
ON e2.emp_id = b.manager_id;

-- Task 12. Create a Table of Books with Rental Price Above 5

CREATE TABLE Rental_Price_Above_5
AS
SELECT *
FROM books
WHERE rental_price > 5;


SELECT *
FROM Rental_Price_Above_5;


-- Task 13: Retrieve the List of Books Not Yet Returned

SELECT *
FROM issued_status AS ist
LEFT JOIN return_status AS rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;

-- Advance Data Analytics

-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books(assume a 30-day return period). 
-- Display the member's_id, member's name, book title, issue date, and days overdue.



# Library_Management

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
    COUNT(*) AS No_Book_Issued
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY COUNT(*)DESC;

SELECT
    e.emp_name,
    ist.issued_emp_id,
    COUNT(*) AS No_Book_Issued
FROM issued_status AS ist
JOIN employees AS e
    ON ist.issued_emp_id = e.emp_id
GROUP BY ist.issued_emp_id, e.emp_name
HAVING COUNT(*) > 1
ORDER BY No_Book_Issued DESC;



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
GROUP BY category
ORDER BY COUNT(*) DESC;


-- Task 8. Retrieve All Books From "Classic" Category:

SELECT 
	isbn,
    book_title,
    category,
    rental_price AS rental_price_in_£,
    publisher
FROM books
WHERE category = 'Classic';

-- Task 9: Find Total Rental Income by Category:
SELECT 
	b.category,
    SUM(b.rental_price) AS rent_by_category_in_£,
    COUNT(*) AS issued_frequency
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
    e2.emp_name AS Manager,
    e1.emp_position,
    e1.*
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
-- Display the member's_id, member's name, book title, issue date, and days.

SELECT 
	ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    DATE("2024-05-15") - ist.issued_date AS over_due_days
FROM issued_status as ist
JOIN members AS m
	ON m.member_id = ist.issued_member_id
JOIN books as bk
	ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rs
	ON rs.issued_id = ist.issued_id
WHERE
	rs.return_date IS NULL
    AND 
    DATE("2024-05-15") - ist.issued_date
ORDER BY 1;
    
    
-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned 
-- (based on entries in the return_status table).
    
 DELIMITER $$
	
CREATE PROCEDURE add_return_records(
	IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(10),
    IN p_book_quality VARCHAR(10)
)
BEGIN
	DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);
    
-- Insert into return_status

	INSERT INTO return_status(return_id,issued_id, return_date, book_quality)
    VALUES(p_return_id, p_issued_id, CURDATE(), p_book_quality);
    
-- Get book ISBN and name from issued_status

	SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;
    
    
-- Update the book status to 'Yes'

	UPDATE books
    SET o_status = 'yes'
    WHERE isbn = v_isbn;
    
-- Display a message

	SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;
    
END$$

DELIMITER ;

CALL add_return_records('RS138', 'IS135', 'Good');


-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, 
-- the number of books returned, and the total revenue generated from book rentals.

CREATE TABLE branch_report
AS
    
SELECT
	b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) AS num_of_book_issued,
    COUNT(rs.return_id) AS num_of_book_returned,
    SUM(bk.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN employees as e
	ON e.emp_id = ist.issued_emp_id
JOIN branch as b
	ON e.branch_id = b.branch_id
LEFT JOIN return_status as rs
	ON rs.issued_id = ist.issued_id
JOIN books as bk
	ON ist.issued_book_isbn = bk.isbn
GROUP BY 1,2;

SELECT *
FROM branch_report;

-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
-- containing members who have issued at least one book in the last 2 months.

CREATE TABLE active_members AS
SELECT * 
FROM members
WHERE member_id IN (
	SELECT DISTINCT issued_member_id
	FROM issued_status
	WHERE issued_date >= DATE("2025-5-15") - INTERVAL 2 month
);

SELECT * 
FROM active_members;
						
    
-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.
    
SELECT
	e.emp_name,
    b.*,
    COUNT(ist.issued_id) AS num_of_book_issued
FROM issued_status AS ist
JOIN employees AS e
ON e.emp_id = ist.issued_emp_id
JOIN branch as b
ON e.branch_id = b.branch_id
GROUP BY 1,2
ORDER BY COUNT(ist.issued_id) DESC
LIMIT 3;


-- Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
-- Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
-- The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
-- The procedure should first check if the book is available (status = 'yes'). If the book is available, 
-- it should be issued, and the status in the books table should be updated to 'no'. If the book is not available 
-- (status = 'no'), the procedure should return an error message indicating that the book is currently not available.


DELIMITER $$

CREATE PROCEDURE issue_book (
    IN p_issued_id VARCHAR(10),
    IN p_issued_member_id VARCHAR(30),
    IN p_issued_book_isbn VARCHAR(30),
    IN p_issued_emp_id VARCHAR(10)
)
BEGIN
    DECLARE v_status VARCHAR(10);

    -- Get current book status
    SELECT o_status 
    INTO v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    -- Check if book is available
    IF v_status = 'yes' THEN
        -- Insert into issued_status
        INSERT INTO issued_status (issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id);

        -- Update book status to 'no'
        UPDATE books
        SET o_status = 'no'
        WHERE isbn = p_issued_book_isbn;

        SELECT CONCAT('Book records added successfully for book ISBN: ', p_issued_book_isbn) AS Message;

    ELSE
        SELECT CONCAT('Sorry, the book is unavailable. ISBN: ', p_issued_book_isbn) AS Message;
    END IF;
END $$

DELIMITER ;

SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';
    
    
-- Task 18: Identify Members Issuing High-Risk Books
-- Write a query to identify members who have issued books more than twice with the status "damaged" 
-- in the books table. Display the member name, book title, and the number of times they've issued damaged books.

SELECT * FROM books;
SELECT * FROM branch; 
SELECT * FROM employees;  
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;
    
-- Solution Q.18 - 

CREATE TABLE overdue_members_report AS
SELECT 
    ist.issued_member_id AS member_id,
    
    -- Count of books overdue more than 30 days
    COUNT(CASE 
            WHEN rs.return_date IS NULL 
                 AND DATEDIFF(CURDATE(), ist.issued_date) > 30 
            THEN 1 
         END) AS overdue_books,
         
    -- Total fine: $0.50 per day * overdue days
    ROUND(SUM(CASE 
                WHEN rs.return_date IS NULL 
                     AND DATEDIFF(CURDATE(), ist.issued_date) > 30 
                THEN (DATEDIFF(CURDATE(), ist.issued_date) - 30) * 0.50
                ELSE 0
              END), 2) AS total_fines,

    -- Total books issued (regardless of return)
    COUNT(ist.issued_id) AS total_books_issued

FROM issued_status AS ist
LEFT JOIN return_status AS rs
    ON rs.issued_id = ist.issued_id
GROUP BY ist.issued_member_id;

SELECT * FROM overdue_members_report;
    


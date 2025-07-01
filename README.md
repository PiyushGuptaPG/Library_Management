-- Library_Management Project SQL Script

-- Task 1: Insert a New Book Record
INSERT INTO books(isbn, book_title, category, rental_price, o_status, author, publisher)
VALUES ('978-1-60129-456-2','To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- Task 2: Update an Existing Member's Address
UPDATE members SET memeber_address = '125 Main St' WHERE member_id = 'C101';

-- Task 4: Retrieve All Books Issued by a Specific Employee
SELECT * FROM issued_status WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book
SELECT e.emp_name, ist.issued_emp_id, COUNT(*) AS No_Book_Issued
FROM issued_status AS ist
JOIN employees AS e ON ist.issued_emp_id = e.emp_id
GROUP BY ist.issued_emp_id, e.emp_name
HAVING COUNT(*) > 1
ORDER BY No_Book_Issued DESC;

-- Task 6: Create Summary Table of Books with Total Issue Count
CREATE TABLE book_cnt AS
SELECT b.isbn, book_title, COUNT(ist.issued_id) AS Num_Issued
FROM books AS b
JOIN issued_status AS ist ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, book_title;

-- Task 7: Retrieve Book Categories with Book Count
SELECT category, COUNT(*) AS total_books
FROM books
GROUP BY category
ORDER BY total_books DESC;

-- Task 8: Retrieve Books From "Classic" Category
SELECT isbn, book_title, category, rental_price AS rental_price_in_£, publisher
FROM books
WHERE category = 'Classic';

-- Task 9: Total Rental Income by Book Category
SELECT b.category, SUM(b.rental_price) AS rent_by_category_in_£, COUNT(*) AS issued_frequency
FROM books AS b
JOIN issued_status AS ist ON ist.issued_book_isbn = b.isbn
GROUP BY b.category
ORDER BY rent_by_category_in_£ DESC;

-- Task 10: List Members Registered in 2021
SELECT * FROM members WHERE YEAR(reg_date) = 2021;

-- Task 11: Employees with Their Branch Manager and Details
SELECT e1.emp_id, e1.emp_name, e2.emp_name AS Manager, e1.emp_position, e1.*
FROM employees AS e1
JOIN branch AS b ON e1.branch_id = b.branch_id
JOIN employees AS e2 ON e2.emp_id = b.manager_id;

-- Task 12: Create Table for Books with Rental Price Above 5
CREATE TABLE Rental_Price_Above_5 AS
SELECT * FROM books WHERE rental_price > 5;

-- Task 13: List of Books Not Yet Returned
SELECT *
FROM issued_status AS ist
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;

-- Task 14: Identify Members with Overdue Books (30 Days)
SELECT ist.issued_member_id, m.member_name, bk.book_title, ist.issued_date, DATE('2024-05-15') - ist.issued_date AS over_due_days
FROM issued_status AS ist
JOIN members AS m ON m.member_id = ist.issued_member_id
JOIN books AS bk ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL AND DATE('2024-05-15') - ist.issued_date > 30
ORDER BY ist.issued_member_id;

-- Task 15: Stored Procedure to Add Return Record and Update Book Status
DELIMITER $$
CREATE PROCEDURE add_return_records(
	IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(10),
    IN p_book_quality VARCHAR(10)
)
BEGIN
	DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

	INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURDATE(), p_book_quality);

	SELECT issued_book_isbn, issued_book_name INTO v_isbn, v_book_name
    FROM issued_status WHERE issued_id = p_issued_id;

	UPDATE books SET o_status = 'yes' WHERE isbn = v_isbn;

	SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;
END $$
DELIMITER ;

-- Task 16: Branch Performance Report
CREATE TABLE branch_report AS
SELECT b.branch_id, b.manager_id,
       COUNT(ist.issued_id) AS num_of_book_issued,
       COUNT(rs.return_id) AS num_of_book_returned,
       SUM(bk.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN employees AS e ON e.emp_id = ist.issued_emp_id
JOIN branch AS b ON e.branch_id = b.branch_id
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
JOIN books AS bk ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.manager_id;

-- Task 17: Create Table for Active Members (Issued in Last 2 Months)
CREATE TABLE active_members AS
SELECT * FROM members
WHERE member_id IN (
	SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= DATE('2025-05-15') - INTERVAL 2 MONTH
);

-- Task 18: Top 3 Employees with Most Issued Books
SELECT e.emp_name, b.*, COUNT(ist.issued_id) AS num_of_book_issued
FROM issued_status AS ist
JOIN employees AS e ON e.emp_id = ist.issued_emp_id
JOIN branch AS b ON e.branch_id = b.branch_id
GROUP BY e.emp_name, b.branch_id
ORDER BY num_of_book_issued DESC
LIMIT 3;

-- Task 19: Procedure to Manage Book Issue Based on Availability
DELIMITER $$
CREATE PROCEDURE issue_book (
    IN p_issued_id VARCHAR(10),
    IN p_issued_member_id VARCHAR(30),
    IN p_issued_book_isbn VARCHAR(30),
    IN p_issued_emp_id VARCHAR(10)
)
BEGIN
    DECLARE v_status VARCHAR(10);

    SELECT o_status INTO v_status FROM books WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN
        INSERT INTO issued_status (issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id);

        UPDATE books SET o_status = 'no' WHERE isbn = p_issued_book_isbn;

        SELECT CONCAT('Book records added successfully for book ISBN: ', p_issued_book_isbn) AS Message;
    ELSE
        SELECT CONCAT('Sorry, the book is unavailable. ISBN: ', p_issued_book_isbn) AS Message;
    END IF;
END $$
DELIMITER ;

-- Task 20: Create Overdue Members Report with Fine Calculation
CREATE TABLE overdue_members_report AS
SELECT ist.issued_member_id AS member_id,
       COUNT(CASE WHEN rs.return_date IS NULL AND DATEDIFF(CURDATE(), ist.issued_date) > 30 THEN 1 END) AS overdue_books,
       ROUND(SUM(CASE WHEN rs.return_date IS NULL AND DATEDIFF(CURDATE(), ist.issued_date) > 30 THEN (DATEDIFF(CURDATE(), ist.issued_date) - 30) * 0.50 ELSE 0 END), 2) AS total_fines,
       COUNT(ist.issued_id) AS total_books_issued
FROM issued_status AS ist
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
GROUP BY ist.issued_member_id;

-- Project Overview & Conclusion
-- This project demonstrates the implementation of a Library Management System using MySQL. 
-- It includes CRUD operations, joins, aggregate analysis, CTAS for summary tables, and stored procedures for transactional logic like issuing and returning books. 
-- The project helps develop SQL proficiency in relational design, reporting, and business logic automation. Ideal for showcasing SQL project experience on GitHub or LinkedIn.

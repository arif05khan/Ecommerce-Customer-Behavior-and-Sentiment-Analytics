-- ***************************** Customer Purchase Behavior and Sentiment Analysis *********************************

-- -----------------------------------------------------------------------------------------------------------------
# Setup a Database: Create a database to store the customer purchase data.
CREATE DATABASE customer_purchase_DB;

-- using the the database
USE customer_purchase_DB;

-- ------------------------------------------------------------------------------------------------------------------
# Data Ingestion: Write SQL scripts to import the provided purchase data into the database.

-- to create a table for the purchase data
CREATE TABLE PurchaseData (
    TransactionID INT PRIMARY KEY,
    CustomerID INT,
    CustomerName VARCHAR(100),
    ProductID INT,
    ProductName VARCHAR(100),
    ProductCategory VARCHAR(50),
    PurchaseQuantity INT,
    PurchasePrice DECIMAL(10, 2),
    PurchaseDate DATE,
    Country VARCHAR(100)
);

-- This will show the directory path where MySQL allows file imports.
SHOW VARIABLES LIKE "secure_file_priv";

-- Use the LOAD DATA INFILE command in MySQL, pointing it to this directory:
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customer_purchase_data.csv"
INTO TABLE PurchaseData
FIELDS TERMINATED BY ','
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(TransactionID, CustomerID, CustomerName, ProductID, ProductName, ProductCategory, PurchaseQuantity, PurchasePrice, PurchaseDate, Country);


# Review the the table
SELECT * FROM PurchaseData;

-- to create a table for the review data
CREATE TABLE ReviewData(
	ReviewID INT PRIMARY KEY,
    CustomerID INT,
    ProductID INT,
    ReviewText VARCHAR(255),
    ReviewDate DATE
);


LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customer_reviews_data.csv"
INTO TABLE ReviewData
FIELDS TERMINATED BY ',' -- Specifies that fields in the CSV are separated by commas. 
ENCLOSED BY '"' -- Specifies that text values are enclosed in double quotes.
LINES TERMINATED BY '\n' -- Each row ends with a newline
IGNORE 1 ROWS
(ReviewID,CustomerID,ProductID,ReviewText,@ReviewDate)
SET 
	ReviewDate = str_to_date(@ReviewDate, '%m/%d/%Y');

SELECT * FROM reviewData;

-- ------------------------------------------------------------------------------------------------------------------------
# Data Transformation: Create necessary tables and perform transformations to clean and organize the data. This should include:

-- 1. Create a normalized table for Customers
CREATE TABLE Customers (
	CustomerID 	INT Primary KEY,
    CustomerName VARCHAR(100),
    Country VARCHAR(100)
    );
    
-- Insert normalized Customers
INSERT INTO Customers (CustomerID, CustomerName, Country)
SELECT customerID, SUBSTRING_INDEX(GROUP_CONCAT(CustomerName), ',', 1) AS CustomerName, 
SUBSTRING_INDEX(GROUP_CONCAT(country), ',', 1) AS Country
FROM purchaseData
GROUP BY 1;

SELECT * FROM Customers;

-- 2. Create a normalized table for Product
CREATE TABLE Product(
	ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    ProductCategory VARCHAR(100)
    );

-- Insert normalized Product
INSERT INTO Product(ProductID, ProductName, ProductCategory)
SELECT ProductID, SUBSTRING_INDEX(GROUP_CONCAT(ProductName), ',', 1) AS ProductName, 
SUBSTRING_INDEX(GROUP_CONCAT(ProductCategory), ',', 1) AS ProductCategory
FROM purchaseData
GROUP BY 1;

SELECT * FROM Product;

-- 3. Create a normalized table for Transactions
CREATE TABLE Transactions(
	TransactionID INT PRIMARY KEY,
    CustomerID INT,
    ProductID INT,
    PurchaseQuantity INT,
    PurchasePrice DECIMAL(10, 2),
    PurchaseDate DATE,
    # Creating relationships between tables.
    FOREIGN KEY(CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY(ProductID) REFERENCES Product(ProductID)
);

-- Insert Transactions
INSERT INTO Transactions (TransactionID, CustomerID, ProductID, PurchaseQuantity, PurchasePrice, PurchaseDate)
SELECT TransactionID, CustomerID, ProductID, PurchaseQuantity, PurchasePrice, PurchaseDate
FROM PurchaseData;

SELECT * FROM Transactions;
-- --------------------------------------------------------------------------------------------------------------------------

-- Queries to Aggregate the data

SELECT ROUND(AVG(PurchasePrice),2) As Average_Purchase_per_transaction
FROM Transactions;

SELECT ROUND(SUM(PurchasePrice)/COUNT(DISTINCT CustomerID), 2) AS Total_Purchase_Per_Customer
FROM Transactions;

SELECT ROUND(SUM(PurchasePrice)/COUNT(DISTINCT ProductID), 2) AS Total_Purchase_Per_Product
FROM Transactions;

SELECT CustomerName, COUNT(ReviewID) AS Number_of_reviews
FROM Customers c JOIN reviewData r
ON c.customerID = r.customerID
GROUP BY CustomerName
ORDER BY Number_of_reviews DESC;

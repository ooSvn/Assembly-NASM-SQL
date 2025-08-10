# NASM Assembly Database Simulator

## 📌 Overview

This project is a **simple database management system simulator** implemented in **NASM Assembly**.
It can parse and execute basic SQL-like commands, manage tables stored as `.tbl` files, and perform operations such as **creating tables, inserting records, selecting data, updating values, and deleting records**.

The goal of this project is to practice **low-level programming concepts**, including string parsing, file I/O, and logical processing, while simulating a high-level database operation environment.

---

## 🎯 Features

The program supports the following commands:

### Table Management

* **CREATE TABLE** – Create a new table with a specified structure.
* **DESCRIBE** – Show table structure (columns and types).
* **DROP TABLE** – Delete a table completely.
* **SHOW TABLES** – List all existing tables in the current directory.

### Data Manipulation

* **INSERT INTO** – Add a new record to a table.
* **SELECT** – View data from a table, with optional column filtering and conditions.
* **DELETE FROM** – Remove records matching a given condition.

---

## 🗂 Table File Structure

Each table is stored as a `.tbl` file in the following format:

1. **First line:** Column definitions

   ```
   col1:type1,col2:type2,...
   ```

   Types can be:

   * `int` → integer values
   * `str` → string values

2. **Subsequent lines:** Records separated by commas, with strings enclosed in quotes
   Example:

   ```
   1,"ali",20
   ```

---

## 🖥 Command Examples

### Create a table

```
CREATE TABLE students (id:int,name:str,age:int)
```

### Insert a record

```
INSERT INTO students VALUES (1,"reza",22)
```

### Select all data

```
SELECT * FROM students
```

### Select specific columns

```
SELECT name,age FROM students
```

### Conditional select

```
SELECT * FROM students WHERE age=22
```

### Delete records

```
DELETE FROM students WHERE id>1
```


## ⚠ Error Messages

The program handles common errors and displays clear messages, such as:

* `Error:Table not found`
* `Error:Invalid CREATE syntax`
* `Error:Invalid number of values`
* `Error:Type mismatch`
* `Error:Column not found`
* `Error:Invalid or corrupted table file`
* `Error:Table already exists`

---

## 🛠 Implementation Notes

* Written entirely in **NASM Assembly**.
* Uses **text parsing** to interpret SQL-like commands.
* File I/O is used for table creation, reading, and writing.
* Includes error handling for invalid commands, wrong data types, and corrupted files.

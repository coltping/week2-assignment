-- seed_data.sql — loads books.csv and sample data into library.db
-- Run from this folder:  sqlite3 library.db < schema.sql  then  sqlite3 library.db < seed_data.sql
PRAGMA foreign_keys = ON;

-- 1. Stage the raw CSV (books.csv itself is left unchanged).
.import --csv --schema temp books.csv raw_books

-- 2. Books: the first 30 titles.
--    isbn13 in the CSV is in scientific notation (digits lost), so use the
--    ISBN-10 column and restore leading zeros the CSV dropped.
INSERT INTO books (book_id, title, original_title, isbn, publication_year, language_code)
SELECT CAST(book_id AS INTEGER),
       title,
       NULLIF(original_title, ''),
       CASE WHEN isbn = '' THEN NULL ELSE substr('0000000000' || isbn, -10) END,
       CAST(CAST(NULLIF(original_publication_year, '') AS REAL) AS INTEGER),
       NULLIF(language_code, '')
FROM temp.raw_books
WHERE CAST(book_id AS INTEGER) <= 30;

-- 3. Authors: split the comma-separated "authors" field, collapse extra spaces.
CREATE TEMP TABLE split_authors AS
WITH RECURSIVE parts(book_id, n, name, rest) AS (
    SELECT CAST(book_id AS INTEGER), 0, NULL, authors || ','
    FROM temp.raw_books WHERE CAST(book_id AS INTEGER) <= 30
    UNION ALL
    SELECT book_id, n + 1,
           trim(substr(rest, 1, instr(rest, ',') - 1)),
           substr(rest, instr(rest, ',') + 1)
    FROM parts WHERE rest <> ''
)
SELECT book_id, n AS author_order,
       replace(replace(replace(replace(name, '    ', ' '), '   ', ' '), '  ', ' '), '  ', ' ') AS name
FROM parts WHERE n > 0 AND name <> '';

INSERT INTO authors (name)
SELECT DISTINCT name FROM split_authors ORDER BY name;

INSERT INTO book_authors (book_id, author_id, author_order)
SELECT s.book_id, a.author_id, s.author_order
FROM split_authors s JOIN authors a ON a.name = s.name;

-- 4. Copies: 1-3 copies per title, numbered in book order.
WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 3)
INSERT INTO copies (book_id, acquired_date, condition)
SELECT b.book_id, '2026-01-15', CASE WHEN n.i = 1 THEN 'good' ELSE 'new' END
FROM books b JOIN n ON n.i <= (b.book_id % 3) + 1
ORDER BY b.book_id, n.i;

-- 5. Members (member 6 has never borrowed anything).
INSERT INTO members (member_id, first_name, last_name, email, phone, joined_date) VALUES
  (1, 'George',   'Washington', 'george.washington@example.com', '405-555-0101', '2026-02-01'),
  (2, 'Thomas',   'Jefferson',  'thomas.jefferson@example.com',  '405-555-0102', '2026-02-14'),
  (3, 'Abraham',  'Lincoln',    'abraham.lincoln@example.com',   '405-555-0103', '2026-03-03'),
  (4, 'Theodore', 'Roosevelt',  'theodore.roosevelt@example.com','405-555-0104', '2026-04-20'),
  (5, 'John',     'Kennedy',    'john.kennedy@example.com',      '405-555-0105', '2026-05-09'),
  (6, 'Calvin',   'Coolidge',   'calvin.coolidge@example.com',   '405-555-0106', '2026-10-01');

-- 6. Loans (21-day loan period).
INSERT INTO loans (copy_id, member_id, checkout_date, due_date, returned_date) VALUES
  -- returned
  ( 1, 1, '2026-08-01', '2026-08-22', '2026-08-20'),
  ( 3, 2, '2026-08-05', '2026-08-26', '2026-08-24'),
  ( 7, 1, '2026-09-01', '2026-09-22', '2026-09-15'),
  ( 9, 3, '2026-09-03', '2026-09-24', '2026-09-30'),   -- returned late
  (12, 4, '2026-09-10', '2026-10-01', '2026-09-28'),
  ( 3, 5, '2026-09-01', '2026-09-22', '2026-09-20'),
  ( 9, 4, '2026-10-05', '2026-10-26', '2026-10-22'),
  ( 4, 3, '2026-10-01', '2026-10-22', '2026-10-21'),
  -- still out, not yet due
  (13, 2, '2026-10-20', '2026-11-10', NULL),
  ( 1, 3, '2026-10-15', '2026-11-05', NULL),
  (19, 4, '2026-10-25', '2026-11-15', NULL),
  -- still out and overdue
  (15, 5, '2026-09-20', '2026-10-11', NULL),
  (18, 1, '2026-09-25', '2026-10-16', NULL),
  -- never came back: copy marked lost below, loan kept as the record
  ( 6, 2, '2026-07-10', '2026-07-31', NULL);

UPDATE copies SET status = 'lost', status_date = '2026-09-01' WHERE copy_id = 6;

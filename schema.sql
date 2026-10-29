-- schema.sql — structure of library.db (MSAI-5523, Module 2)
PRAGMA foreign_keys = ON;

-- A title the library carries (one row per Goodbooks-10k book).
CREATE TABLE books (
    book_id          INTEGER PRIMARY KEY,          -- same id as books.csv
    title            TEXT    NOT NULL,
    original_title   TEXT,
    isbn             TEXT,                         -- ISBN-10, kept as text
    publication_year INTEGER,
    language_code    TEXT
);

-- A person credited on a book (author, illustrator, translator...).
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    name      TEXT NOT NULL UNIQUE
);

-- Many-to-many link between books and authors.
CREATE TABLE book_authors (
    book_id      INTEGER NOT NULL REFERENCES books(book_id),
    author_id    INTEGER NOT NULL REFERENCES authors(author_id),
    author_order INTEGER NOT NULL,                 -- 1 = first-listed author
    PRIMARY KEY (book_id, author_id)
);

-- A physical copy on the shelf. Members borrow copies, not titles.
-- "On loan" and "overdue" are not stored here; they come from loans.
CREATE TABLE copies (
    copy_id       INTEGER PRIMARY KEY,
    book_id       INTEGER NOT NULL REFERENCES books(book_id),
    acquired_date TEXT    NOT NULL,
    condition     TEXT    NOT NULL DEFAULT 'good'
                  CHECK (condition IN ('new', 'good', 'worn', 'damaged')),
    status        TEXT    NOT NULL DEFAULT 'in_collection'
                  CHECK (status IN ('in_collection', 'lost', 'withdrawn')),
    status_date   TEXT                             -- when lost / withdrawn
);

-- A person with a library card.
CREATE TABLE members (
    member_id   INTEGER PRIMARY KEY,
    first_name  TEXT    NOT NULL,
    last_name   TEXT    NOT NULL,
    email       TEXT    NOT NULL UNIQUE,
    phone       TEXT,
    joined_date TEXT    NOT NULL,
    is_active   INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);

-- One borrowing of one copy by one member. Never deleted: this is the history.
CREATE TABLE loans (
    loan_id       INTEGER PRIMARY KEY,
    copy_id       INTEGER NOT NULL REFERENCES copies(copy_id),
    member_id     INTEGER NOT NULL REFERENCES members(member_id),
    checkout_date TEXT    NOT NULL,
    due_date      TEXT    NOT NULL,
    returned_date TEXT,                            -- NULL = still out
    CHECK (due_date > checkout_date),
    CHECK (returned_date IS NULL OR returned_date >= checkout_date)
);

-- A copy can be on only one open loan at a time.
CREATE UNIQUE INDEX one_open_loan_per_copy
    ON loans(copy_id) WHERE returned_date IS NULL;

-- Current status of every copy, derived so it can never go stale.
CREATE VIEW copy_status AS
SELECT c.copy_id,
       c.book_id,
       b.title,
       CASE
           WHEN c.status <> 'in_collection'      THEN c.status
           WHEN l.loan_id IS NULL                THEN 'available'
           WHEN l.due_date < date('now')         THEN 'overdue'
           ELSE 'on_loan'
       END AS status,
       l.member_id,
       l.due_date
FROM copies c
JOIN books b ON b.book_id = c.book_id
LEFT JOIN loans l ON l.copy_id = c.copy_id AND l.returned_date IS NULL;

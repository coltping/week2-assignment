# Part 2 – Thinking like a library owner

## What does a library do every day?
- Lends books to members and gets them back.
- Checks whether a book is on the shelf before promising it to someone.
- Follows up on books that are late.
- Signs up new members, and sometimes deactivates old ones.
- Adds new books, and removes worn-out or lost ones.

## What does the library need to know about a book?
There are two different things here:
- **The title** (the "work"): title, author(s), publication year, ISBN, language. Goodreads gives one row per title.
- **The physical copy** on the shelf: which title it is, when we got it, its condition, and its status (available, on loan, lost, withdrawn).
  - A popular title like *The Hunger Games* might have 3 copies. Members borrow a *copy*, not a title.

## What does it need to know about an author?
- Name. One author writes many books, and one book can have several authors (e.g. *J.K. Rowling, Mary GrandPré* in books.csv).
- So authors get their own list, plus a link list that pairs books with authors (and the order the authors are listed in).

## What does it need to know about a member?
- Name, email, phone, the date they joined, and whether their membership is active.
- A member can have many loans over time, or none at all.

## What does it need to know about a borrowing (loan)?
- Which copy, which member, the checkout date, the due date, and the return date (empty while the book is still out).
- **Still out** = no return date.
- **Overdue** = no return date and the due date is in the past. This is calculated, not stored, so it can't go out of date.
- Keep every loan forever. That's the borrowing history.

## Rules of my library
- The loan period is 21 days.
- A member can have at most 5 books out at once.
- A copy can only be on one active loan at a time.
- If a book is lost, the copy is marked **lost** with the date. The loan record stays so we know who had it last. Copies are never deleted.

## Out of scope (for now)
- Fines, holds/reservations, and multiple branches. I could add them later as extra tables.

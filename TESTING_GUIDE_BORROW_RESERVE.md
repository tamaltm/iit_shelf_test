# Quick Testing Guide - Book Borrow, Return & Reserve System

## Environment Setup

### Prerequisites
- Flutter SDK installed
- PHP 8.5+ with MySQL/MariaDB
- Postman or curl (for API testing)

### Starting the Services

**1. Start Backend Server**
```bash
cd /mnt/academics/iit_shelf_test/backend
php -S localhost:8000 router.php
```

**2. Start Flutter App**
```bash
cd /mnt/academics/iit_shelf_test
flutter run -d linux
```

---

## Test Users

Use these credentials for testing different roles:

| Email | Name | Role | Password |
|-------|------|------|----------|
| api.test@iit.edu | API Test User | Student | (OTP based) |
| brandnew@iit.edu | Brand New | Student | (OTP based) |
| librarian@iit.edu | Test Librarian | Librarian | (OTP based) |
| director@iit.edu | Test Director | Director | (OTP based) |

---

## Manual Testing Scenarios

### Scenario 1: Student Borrows a Book

**Step 1**: Login as api.test@iit.edu
- App → Login page → Enter email
- Check inbox for OTP
- Enter OTP → Login successful

**Step 2**: Browse books
- Dashboard → "Browse Books" or navigate via menu
- Scroll to find "Introduction to Algorithms" (ISBN: 978-0-13-110362-7)

**Step 3**: Borrow the book
- Click on book card
- Click "Borrow" button
- Success message appears: "Book borrowed successfully"

**Step 4**: Verify in Borrowed tab
- Navigate to "Borrowed" tab
- Book appears with:
  - Title: "Introduction to Algorithms"
  - Issue Date: Today's date
  - Due Date: 14 days from today
  - Status: "Borrowed"

**Expected Result**: ✅ Book appears in borrowed list with correct dates

---

### Scenario 2: Student Returns a Book

**Step 1**: Open Borrowed tab
- Navigate to "Borrowed" tab
- Find the book borrowed in Scenario 1

**Step 2**: Return the book
- Click "Return" button on the book card
- Confirmation dialog appears: "Are you sure you want to return...?"
- Click "Yes" to confirm

**Step 3**: Verify return
- Success message: "Book returned successfully"
- Book disappears from Borrowed tab (or updates to Returned status)

**Step 4**: Check Returned tab
- Navigate to "Returned" tab
- Book appears with:
  - Return Date: Today
  - Status: "Returned"
  - Fine: 0 (if returned before due date)

**Expected Result**: ✅ Book moves to returned list, fine = 0

---

### Scenario 3: Student Reserves an Unavailable Book

**Step 1**: Borrow all copies of a book
- Find "Operating System Concept" (1 copy available)
- Borrow it as described in Scenario 1

**Step 2**: Try to borrow another copy
- Login as brandnew@iit.edu
- Find same book
- Click "Borrow" button
- Error: "No available copies"
- Button changes to "Reserve"

**Step 3**: Reserve the book
- Click "Reserve" button
- Success message: "Book reserved successfully"
- Shows queue position: "You are 1st in queue"

**Step 4**: Verify in Reserved tab
- Navigate to "Reserved" tab
- Book appears with:
  - Queue Position: 1
  - Expiry Date: 7 days from today
  - Status: "Active"

**Expected Result**: ✅ Book reserved with queue position and expiry date

---

### Scenario 4: Student Cancels Reservation

**Step 1**: Open Reserved tab
- Navigate to "Reserved" tab
- Find the reserved book from Scenario 3

**Step 2**: Cancel reservation
- Click "Cancel Queue" button
- Confirmation dialog: "Are you sure you want to cancel...?"
- Click "Yes"

**Step 3**: Verify cancellation
- Success message: "Reservation cancelled successfully"
- Book disappears from Reserved tab

**Expected Result**: ✅ Reservation cancelled, book removed from list

---

## API Testing (Curl)

### Test 1: Get Available Books
```bash
curl -X GET "http://localhost:8000/books/get_books.php" | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "books": [
    {
      "isbn": "978-0-13-110362-7",
      "title": "Introduction to Algorithms",
      "copies_available": 2,
      ...
    }
  ]
}
```

---

### Test 2: Borrow a Book
```bash
curl -X POST "http://localhost:8000/borrow/borrow_book.php" \
  -H "Content-Type: application/json" \
  -d '{
    "isbn": "978-0-13-110362-7",
    "user_email": "api.test@iit.edu"
  }' | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Book borrowed successfully",
  "transaction_id": 1,
  "copy_id": "978-0-13-110362-7-001"
}
```

---

### Test 3: Get User Transactions
```bash
curl -X GET "http://localhost:8000/borrow/get_user_transactions.php?email=api.test@iit.edu&status=borrowed" | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "count": 1,
  "transactions": [
    {
      "type": "borrowed",
      "transaction_id": 1,
      "title": "Introduction to Algorithms",
      "issue_date": "2026-01-06",
      "due_date": "2026-01-20",
      "status": "Borrowed"
    }
  ]
}
```

---

### Test 4: Return a Book
```bash
curl -X POST "http://localhost:8000/borrow/return_book.php" \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": 1
  }' | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Book returned successfully",
  "fine": 0,
  "fine_id": null
}
```

---

### Test 5: Reserve a Book
```bash
curl -X POST "http://localhost:8000/books/reserve_book.php" \
  -H "Content-Type: application/json" \
  -d '{
    "isbn": "978-0-134-68599-1",
    "user_email": "api.test@iit.edu"
  }' | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Book reserved successfully",
  "reservation_id": 1,
  "queue_position": 1
}
```

---

### Test 6: Cancel Reservation
```bash
curl -X POST "http://localhost:8000/books/cancel_reservation.php" \
  -H "Content-Type: application/json" \
  -d '{
    "reservation_id": 1,
    "user_email": "api.test@iit.edu"
  }' | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Reservation cancelled"
}
```

---

## Database Verification

### Check Book Copies Status
```bash
sudo mysql iit_shelf -e "SELECT copy_id, isbn, status FROM Book_Copies LIMIT 5;"
```

**Expected**: Statuses should be "Available", "Borrowed", or "Discarded"

### Check Transactions
```bash
sudo mysql iit_shelf -e "SELECT transaction_id, requester_email, status FROM Transaction_Requests LIMIT 5;"
```

**Expected**: Statuses should be "Approved", "Rejected"

### Check Approved Transactions
```bash
sudo mysql iit_shelf -e "SELECT transaction_id, copy_id, status FROM Approved_Transactions LIMIT 5;"
```

**Expected**: Statuses should be "Borrowed" or "Returned"

### Check Reservations
```bash
sudo mysql iit_shelf -e "SELECT reservation_id, user_email, queue_position, status FROM Reservations LIMIT 5;"
```

**Expected**: Statuses should be "Active", "Cancelled", or "Completed"

---

## Performance Metrics

### Page Load Times (Expected)
- Books List: < 1 second
- Borrowed Books: < 1.5 seconds
- Reserved Books: < 1.5 seconds
- Book Detail: < 1 second

### API Response Times (Expected)
- Get Books: < 500ms
- Get Transactions: < 800ms
- Borrow Book: < 1000ms
- Return Book: < 1000ms
- Reserve Book: < 1000ms

---

## Error Cases to Test

### Test: Borrow without login
**Action**: Try to borrow without entering email
**Expected**: Error message "User not logged in"

### Test: Borrow unavailable book
**Action**: Try to borrow when no copies available
**Expected**: Error "No available copies" + Reserve button shown

### Test: Return non-existent transaction
**API Call**: `curl -X POST "..." -d '{"transaction_id": 99999}'`
**Expected**: Error "Transaction not found"

### Test: Duplicate reservation
**Action**: Try to reserve same book twice
**Expected**: Error "You already have an active reservation for this book"

### Test: Invalid transaction ID
**API Call**: `curl -X POST "..." -d '{"transaction_id": "abc"}'`
**Expected**: Error "Invalid transaction ID"

---

## Regression Testing Checklist

- [ ] Login/Logout working
- [ ] Profile image displays correctly
- [ ] App bar shows real user name
- [ ] Books list loads without deleted books
- [ ] Book detail page shows correct availability
- [ ] Borrow button works for available books
- [ ] Borrow creates transaction record
- [ ] Borrowed tab shows correct books
- [ ] Return button works
- [ ] Return updates status correctly
- [ ] Returned tab shows correct books
- [ ] Reserve button works for unavailable books
- [ ] Reserved tab shows correct books
- [ ] Cancel reservation works
- [ ] Fine calculation correct for overdue books
- [ ] All user roles can access their features
- [ ] Network errors handled gracefully

---

## Known Issues & Workarounds

### Issue: Profile image doesn't update immediately
**Cause**: Image cached in memory
**Workaround**: Hot restart app (`r`) or restart completely

### Issue: Borrowed tab empty on first load
**Cause**: API call takes time
**Workaround**: Pull to refresh or wait 2 seconds

### Issue: Navigation sometimes stutters
**Cause**: Heavy image loading
**Workaround**: Images optimized, preload in background

---

## Support & Debugging

### Enable Debug Logs
```bash
flutter run -v
```

### Check Backend Logs
```bash
tail -f /var/log/php-errors.log
```

### Check Database Logs
```bash
sudo tail -f /var/log/mysql/mysql.log
```

### Reset Database
```bash
sudo mysql iit_shelf < /path/to/database/backup.sql
```

---

## Conclusion

All tests should pass within the expected timeframes. If any test fails:
1. Check error message in snackbar/dialog
2. Review backend logs for API errors
3. Verify database has test data
4. Ensure network connection to localhost:8000
5. Check database connection credentials

For critical issues, contact the development team with:
- Screenshot of error
- Backend API log snippet
- Database state (query results)
- Step-by-step reproduction instructions

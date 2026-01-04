# Profile Image Upload Implementation Guide

## Overview
Complete implementation of profile image upload and profile retrieval feature with database integration.

## Backend Endpoints

### 1. Upload Profile Image
**Endpoint:** `POST /auth/upload_profile_image.php`

**Request:**
- Method: POST (multipart/form-data)
- Fields:
  - `email` (string, required): User email
  - `image` (file, required): Image file (JPEG, PNG, GIF, WebP)

**Validation:**
- File size: Maximum 5MB
- MIME types: image/jpeg, image/png, image/gif, image/webp
- User must exist in database

**Response (Success):**
```json
{
  "success": true,
  "message": "Profile image uploaded successfully.",
  "image_url": "uploads/profiles/abc123.jpg"
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Error description"
}
```

**Database Changes:**
- Saves relative image path to `users.profile_image` column
- Updates `users.updated_at` timestamp
- Images stored in `/backend/uploads/profiles/` directory

---

### 2. Get User Profile
**Endpoint:** `POST /auth/get_profile.php`

**Request:**
- Method: POST (JSON)
- Body:
  ```json
  {
    "email": "user@example.com"
  }
  ```

**Response (Success):**
```json
{
  "success": true,
  "user": {
    "email": "user@example.com",
    "name": "John Doe",
    "phone": "+1234567890",
    "role": "student",
    "profile_image": "uploads/profiles/abc123.jpg",
    "is_active": true,
    "email_verified": true,
    "created_at": "2026-01-04 10:30:00",
    "last_login": "2026-01-04 15:45:00"
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "User not found."
}
```

---

## Flutter Implementation

### AuthService Methods

#### 1. uploadProfileImage()
```dart
static Future<AuthResult> uploadProfileImage(String email, String imagePath) async
```
- Uploads image file to backend
- Returns AuthResult with success/failure
- Automatically updates internal profile cache
- Supports multipart form data

#### 2. getProfile()
```dart
static Future<AuthResult> getProfile(String email) async
```
- Retrieves complete user profile from backend
- Includes all profile data and image URL
- Updates internal profile cache
- Returns AuthResult with success/failure

### Profile Page Updates

**New Features:**
1. **Dynamic Profile Image Display**
   - Shows uploaded image from database
   - Falls back to asset if no image uploaded
   - Local preview while uploading

2. **Camera Button (Edit Icon)**
   - Tappable circle avatar with edit icon
   - Opens device image gallery
   - Shows loading indicator during upload

3. **Dynamic Profile Data**
   - Name from database (not hardcoded)
   - Phone number display
   - Email display
   - Role display from database

4. **Auto-Load on Init**
   - Calls `getProfile()` on page load
   - Displays user data from database
   - Updates UI with real data

### File Picker Integration
- Uses `image_picker` package (v0.8.7+5)
- Supports device gallery selection
- Image quality: 80% compression
- Max dimensions: 1000x1000px

### Error Handling
- Network errors: Toast notification
- Upload failures: Error message display
- Loading state: Spinner during upload
- Success confirmation: Green success toast

---

## Database Schema Changes

**users table profile_image column:**
```sql
ALTER TABLE users ADD COLUMN profile_image VARCHAR(255) NULL;
```

**Data Flow:**
1. User selects image from device
2. Image sent to `upload_profile_image.php`
3. Image validated and stored in `/uploads/profiles/`
4. Path saved to `users.profile_image` column
5. Next time profile loads, image retrieved from database

---

## Testing Procedure

### 1. Register New User
```
1. Open Flutter app
2. Click "Create Account"
3. Email: test@example.com
4. Verify OTP from Gmail
5. Full Name: Test User
6. Phone: +1234567890
7. Password: test123
8. Click Register
```

### 2. Go to Profile Page
```
1. Login with test@example.com / test123
2. Click Profile icon in bottom nav
3. See profile page with camera icon
```

### 3. Upload Profile Image
```
1. Click camera icon on avatar
2. Select image from gallery
3. See loading spinner
4. Success toast appears
5. Profile image updates
```

### 4. Verify Database Storage
```bash
sudo mariadb -e "USE iit_shelf; SELECT email, name, phone, profile_image FROM users WHERE email='test@example.com';"
```

Expected output:
```
+-----------+-----------+-------------+----------------------------------+
| email     | name      | phone       | profile_image                    |
+-----------+-----------+-------------+----------------------------------+
| test@...  | Test User | +123456789  | uploads/profiles/abc123xyz.jpg   |
+-----------+-----------+-------------+----------------------------------+
```

### 5. Restart App and Verify Persistence
```
1. Close Flutter app
2. Reopen Flutter app
3. Login again
4. Navigate to profile
5. Image should load from database
```

---

## API Testing with curl

### Upload Image
```bash
curl -X POST http://localhost:8000/auth/upload_profile_image.php \
  -F "email=test@example.com" \
  -F "image=@/path/to/image.jpg"
```

### Get Profile
```bash
curl -X POST http://localhost:8000/auth/get_profile.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

---

## Directory Structure

```
/backend/
├── api/
│   ├── auth/
│   │   ├── upload_profile_image.php      [NEW]
│   │   ├── get_profile.php               [NEW]
│   │   └── ... (other auth endpoints)
│   ├── config/
│   │   └── database.php
│   └── lib/
│       └── ... (helper files)
└── uploads/
    └── profiles/                          [NEW - auto-created]
        ├── md5hash1.jpg
        ├── md5hash2.png
        └── ...

/lib/
├── profile.dart                           [UPDATED - image upload + dynamic data]
├── auth_service.dart                      [UPDATED - new methods]
└── ... (other pages)
```

---

## Security Features

1. **File Validation**
   - MIME type verification (not just extension)
   - File size limit (5MB)
   - Image dimension limits (1000x1000px)

2. **User Verification**
   - Email must exist in database
   - User authentication required (implicit via email)

3. **Filename Security**
   - MD5 hash of email + timestamp
   - Prevents directory traversal
   - No original filename stored

4. **Image Storage**
   - Stored outside web root considerations
   - Relative path stored in database
   - Accessible via backend static serve

---

## Troubleshooting

**Issue: "Image size must be less than 5MB"**
- Solution: Compress image or select smaller file

**Issue: "Only JPEG, PNG, GIF, and WebP images are allowed"**
- Solution: Convert image to supported format

**Issue: "User not found"**
- Solution: Ensure user email is registered in database

**Issue: Image not showing after upload**
- Solution: Check `/backend/uploads/profiles/` directory exists and has write permissions

**Issue: Database updated but image still doesn't show**
- Solution: Clear Flutter app cache or restart app

---

## Next Steps

1. ✅ Upload profile image feature complete
2. ✅ Database integration complete
3. **Pending:** Profile picture API caching mechanism
4. **Pending:** Image cropping/editing before upload
5. **Pending:** Image deletion endpoint


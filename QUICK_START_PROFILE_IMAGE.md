# 🚀 Profile Image Upload - Quick Start Guide

## What's New?

Your Flutter app now has a complete profile image upload feature with database persistence. Users can:
- ✅ Click a camera icon on their profile
- ✅ Pick an image from their device
- ✅ See the image upload with a loading indicator
- ✅ See the image persist even after closing the app
- ✅ View their profile data (name, phone, email, role) from the database

---

## Testing in 2 Minutes

### Step 1: Verify Server is Running
```bash
ps aux | grep "php -S" | grep -v grep
```
**Expected**: Shows `php -S localhost:8000` in `/backend/api`

### Step 2: Test Get Profile
```bash
curl -s -X POST http://localhost:8000/auth/get_profile.php \
  -H "Content-Type: application/json" \
  -d '{"email":"tamal2517@student.nstu.edu.bd"}' | python3 -m json.tool
```
**Expected**: Returns user data with `profile_image` field

### Step 3: Open Flutter App
```bash
cd /mnt/academics/iit_shelf_test
flutter run
```

### Step 4: Navigate to Profile
1. Login with any test user
2. Click Profile icon (bottom navigation)
3. You'll see profile data and a camera button on the avatar

### Step 5: Upload an Image
1. Click the camera icon (blue circle)
2. Select an image from your gallery
3. See loading spinner
4. Success! Image displays from database

---

## Files You Need to Know About

| File | Purpose |
|------|---------|
| [/backend/api/auth/upload_profile_image.php](backend/api/auth/upload_profile_image.php) | Backend image upload endpoint |
| [/backend/api/auth/get_profile.php](backend/api/auth/get_profile.php) | Backend profile retrieval endpoint |
| [/lib/profile.dart](lib/profile.dart) | Flutter profile page with image picker |
| [/lib/auth_service.dart](lib/auth_service.dart) | AuthService with new upload/profile methods |

---

## How It Works

```
User Flow:
┌─────────────┐
│   Profile   │
│   Page      │
└──────┬──────┘
       │ Click Camera
       ▼
┌─────────────┐      ┌────────────┐
│Image Picker │─────▶│   Upload   │
└─────────────┘      │   Server   │
       ▲             └────────────┘
       │                    │
       │            ┌───────▼───────┐
       │            │    Database   │
       │            │  (save path)  │
       │            └───────────────┘
       │
    Reload and display from DB
```

---

## Key Features

### 1. **Image Upload**
- Accept JPEG, PNG, GIF, WebP
- Max 5MB file size
- Filename hashed for security
- Saved to `/backend/uploads/profiles/`

### 2. **Database Integration**
- Image path stored in `users.profile_image`
- Persists across app restarts
- Accessible from profile retrieval API

### 3. **User Experience**
- Loading indicator while uploading
- Success/error notifications
- Display user's actual name and phone
- Fallback icon if no image

### 4. **Security**
- File type validation (MIME)
- File size limits
- Filename hashing
- User authentication check

---

## API Endpoints

### Upload Image
```
POST /auth/upload_profile_image.php
Content-Type: multipart/form-data

Fields:
  - email: user@example.com
  - image: (file)

Response:
  {
    "success": true,
    "message": "Profile image uploaded successfully.",
    "image_url": "uploads/profiles/hash.jpg"
  }
```

### Get Profile
```
POST /auth/get_profile.php
Content-Type: application/json

Body:
  { "email": "user@example.com" }

Response:
  {
    "success": true,
    "user": {
      "email": "user@example.com",
      "name": "User Name",
      "phone": "+1234567890",
      "role": "Student",
      "profile_image": "uploads/profiles/hash.jpg",
      ...
    }
  }
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "User not found" | Ensure user is registered in database |
| "Image size must be less than 5MB" | Compress the image |
| "Only JPEG, PNG, GIF, and WebP..." | Convert image to supported format |
| Image not showing | Check `/backend/uploads/profiles/` directory has write permissions |
| Network error | Ensure PHP server is running on localhost:8000 |

---

## Complete Documentation

For more details, see:
1. **PROFILE_IMAGE_IMPLEMENTATION.md** - Full technical details
2. **PROFILE_IMAGE_TESTING_GUIDE.md** - Complete testing procedures
3. **FILES_CHANGED.md** - All file changes documented

---

## System Status

| Component | Status | Details |
|-----------|--------|---------|
| Backend API | ✅ Working | 2 endpoints created |
| Flutter App | ✅ Ready | Compiles, 0 errors |
| Database | ✅ Ready | profile_image column active |
| Uploads | ✅ Ready | /backend/uploads/profiles/ ready |

---

## Next Steps

After testing:
1. Register a new user
2. Complete 3-step registration flow
3. Upload a profile image
4. Logout and login again
5. Verify image persists

That's it! Your profile image feature is ready to use.

---

**Questions?** Check the documentation files or test with curl commands above.


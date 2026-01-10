# 🔥 Firebase Storage Setup Guide

## ⚠️ PENTING: Setup Firebase Storage Rules

Sebelum upload gambar, kena setup Firebase Storage rules dulu!

### 1. Go to Firebase Console
1. Pergi ke https://console.firebase.google.com
2. Pilih project: **kedai-bihun-selambak**
3. Sidebar kiri → Klik **Storage**
4. Klik tab **Rules**

### 2. Update Storage Rules

Replace dengan rules ini:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Public read for all menu images (waiter/customer can view)
    match /restaurants/{restaurantId}/menu-images/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null 
                   && request.auth.token.email != null;
      allow delete: if request.auth != null;
    }
    
    // Fallback: deny all other paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 3. Publish Rules
Klik **Publish** button

## ✅ What These Rules Do

1. **Public Read** 
   - Semua orang boleh view gambar menu
   - Penting untuk waiter & customer interface

2. **Authenticated Write**
   - Hanya admin yang login boleh upload
   - Extra security layer

3. **Authenticated Delete**
   - Hanya admin yang login boleh delete
   - Prevent accidental deletion

## 🧪 Test Upload

1. Login sebagai admin
2. Pergi Menu Manager
3. Add new item dengan gambar
4. Check Firebase Console → Storage:
   ```
   restaurants/
     └── kedai_makan/
         └── menu-images/
             └── {itemId}_timestamp.jpg ← Should appear here!
   ```

## ❌ Troubleshooting

### Error: "User does not have permission to access"
**Solution**: Check Storage Rules, make sure public read enabled

### Error: "Storage quota exceeded"
**Solution**: 
- Firebase Free Plan: 5GB storage, 1GB/day download
- Upgrade to Blaze (pay-as-you-go) if needed

### Error: "Upload failed"
**Solution**:
- Check internet connection
- Check file size (should be < 5MB)
- Check file format (JPG, PNG, WebP only)

## 💰 Storage Costs (Firebase Blaze Plan)

| Operation | Free Tier | Cost After |
|-----------|-----------|------------|
| Storage | 5 GB | $0.026/GB/month |
| Download | 1 GB/day | $0.12/GB |
| Upload | Unlimited | $0.05/GB |

**Estimation untuk kedai kecil:**
- 50 menu items × 500KB = ~25MB storage
- Cost: < RM 0.50/month
- Very affordable! 💰

## 🎯 Image Size Optimization

Untuk jimat storage & bandwidth:

```javascript
// Recommended image specs
Max Size: 500KB - 1MB
Dimensions: 800x600px or 1000x1000px (square)
Format: WebP (smallest) > JPG > PNG
Quality: 80-85%
```

### Tools untuk compress:
- **TinyPNG.com** (free online)
- **Squoosh.app** (by Google)
- **ImageOptim** (Mac app)

## 🚀 Ready to Use!

Image upload feature is now **LIVE**! 

Test it:
1. ✅ Login as admin
2. ✅ Menu Manager
3. ✅ Add/Edit menu with images
4. ✅ Images stored in Firebase Storage
5. ✅ URLs saved in Firestore

Next: Display images dalam waiter interface! 🎨

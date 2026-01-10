# 📸 Image Upload Feature - Implementation Guide

## ✅ Completed Features

### Admin Menu Manager
- ✅ Upload gambar semasa tambah menu baru
- ✅ Edit/update gambar untuk menu sedia ada  
- ✅ Delete gambar
- ✅ Preview gambar sebelum upload
- ✅ Gambar disimpan di **Firebase Storage**
- ✅ URL gambar disimpan dalam **Firestore Database**

## 🗂️ Database Structure

### Firestore (`menuItems` collection)
```javascript
{
  name: "Bihun Sup Daging",
  price: 13.00,
  categoryId: "sup",
  imageUrl: "https://firebasestorage.googleapis.com/.../image.jpg", // 🆕
  isAvailable: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Firebase Storage Path
```
restaurants/
  └── kedai_makan/
      └── menu-images/
          ├── {itemId}_1234567890.jpg
          ├── {itemId}_1234567891.jpg
          └── ...
```

## 🎯 How It Works

### 1. Add New Menu Item with Image
1. Admin masuk Menu Manager
2. Fill in: Name, Category, Price
3. Klik "Choose Image" → select gambar
4. Preview gambar akan muncul
5. Klik "Add Item"
6. System akan:
   - Create document dalam Firestore (dapat ID)
   - Upload gambar ke Firebase Storage (guna ID dalam path)
   - Update document dengan `imageUrl`

### 2. Edit Existing Item
1. Klik "Edit" button pada menu item
2. Modal terbuka dengan data sedia ada
3. Untuk tukar gambar:
   - Klik "Change Image" → pilih gambar baru
   - OR klik "Remove Image" untuk buang gambar
4. Klik "Save"
5. System akan:
   - Delete gambar lama (jika ada)
   - Upload gambar baru (jika dipilih)
   - Update Firestore dengan URL baru

### 3. Delete Item
- System akan delete gambar dari Storage sebelum delete document

## 🔧 Firebase Storage Rules

Tambah rules ini dalam Firebase Console:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /restaurants/{restaurantId}/menu-images/{imageId} {
      allow read: if true;  // Anyone can read (for waiter app)
      allow write: if request.auth != null;  // Only authenticated users can write
      allow delete: if request.auth != null;
    }
  }
}
```

## 📱 Next Step: Waiter Interface

### Reception/Order Page (Untuk Waiter)
Tambah display gambar dalam menu selection:

```html
<!-- In reception.html or order.html -->
<div class="menu-item">
  <img src="${item.imageUrl}" alt="${item.name}" 
       onerror="this.src='assets/images/placeholder.jpg'">
  <h5>${item.name}</h5>
  <p>${item.categoryId}</p>
  <p>RM ${item.price}</p>
</div>
```

### Features untuk Waiter:
- ✨ Display menu dengan gambar cantik
- 📷 Jika tiada gambar, tunjuk placeholder icon
- 🖼️ Gambar auto-load dari Firebase Storage URL
- ⚡ Fast loading dengan CDN Firebase

## 🎨 Recommended Image Specs

- **Format**: JPG, PNG, WebP
- **Size**: Max 2MB (optimal: 500KB)
- **Dimensions**: 800x600px atau 1:1 ratio (square)
- **Quality**: Medium-High (80-90%)

## 🚀 Optimization Tips

1. **Compress images** sebelum upload
2. Use **WebP format** untuk size lebih kecil
3. Implement **lazy loading** dalam waiter interface
4. Add **placeholder** untuk better UX

## ✅ Benefits

✨ **Professional look** - Menu nampak lebih menarik
📱 **Better UX** - Waiter/customer boleh nampak visual
🎯 **Easy management** - Admin boleh update anytime
☁️ **Cloud storage** - No server storage issues
⚡ **Fast delivery** - Firebase CDN sangat laju

## 🔜 Future Enhancements

- [ ] Multiple images per item (gallery)
- [ ] Image cropping tool
- [ ] Auto-resize/optimize on upload
- [ ] Image search/filter
- [ ] Bulk image upload

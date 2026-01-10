# 📁 File Reorganization Guide

## 🎯 Struktur Folder Baru (Disarankan)

```
public/
├── index.html                          # Login page (root)
├── assets/                             # 🆕 All static assets
│   ├── images/                         # Menu images, logos
│   │   ├── menu/                       # Menu item photos
│   │   └── placeholder.jpg             # Default image
│   └── sounds/                         # Notification sounds
│       └── neworder.mp3
├── css/                                # 🆕 Stylesheets (if needed)
├── js/                                 # JavaScript files
│   ├── firebase-config.js
│   ├── login.js
│   ├── importMenu.js
│   └── menu.csv
├── pages/                              # 🆕 Organized pages
│   ├── admin/
│   │   ├── dashboard.html              # (dari admin.html)
│   │   ├── menu-manager.html           # (dari menumanager.html)
│   │   ├── table-management.html       # (dari tablemanagement.html)
│   │   ├── staff-management.html       # (dari staffmanagement.html)
│   │   └── groceries-management.html   # (dari groceriesmanagement.html)
│   └── waiter/
│       ├── reception.html              # Order taking
│       ├── order.html                  # Order management
│       └── kds.html                    # Kitchen display
└── package.json

```

## 📋 Steps to Reorganize

### 1. Move Files (Guna terminal)
```powershell
# Move sound file
mv neworder.mp3 assets/sounds/

# Move admin pages
mv admin.html pages/admin/dashboard.html
mv dashboard-admin/menumanager.html pages/admin/menu-manager.html
mv dashboard-admin/tablemanagement.html pages/admin/table-management.html
mv dashboard-admin/staffmanagement.html pages/admin/staff-management.html
mv dashboard-admin/groceriesmanagement.html pages/admin/groceries-management.html

# Move waiter pages
mv reception.html pages/waiter/reception.html
mv order.html pages/waiter/order.html
mv kds.html pages/waiter/kds.html
```

### 2. Update All File Paths
After moving files, update these paths in each file:
- CSS/JS imports
- Navigation links
- Firebase config imports
- Image paths
- Sound file paths

## 🎨 Image Upload Strategy

### Firebase Storage Structure
```
restaurants/
  └── kedai_makan/
      └── menu-images/
          ├── {itemId}_1.jpg
          ├── {itemId}_2.jpg
          └── ...
```

### Firestore Database Structure
```javascript
menuItems/{itemId}:
  - name: "Bihun Sup Daging"
  - price: 13.00
  - categoryId: "sup"
  - imageUrl: "https://firebasestorage.../image.jpg"  // 🆕 Add this
  - isAvailable: true
  - createdAt: timestamp
  - updatedAt: timestamp
```

## ✅ Benefits
- ✨ Lebih organized dan mudah maintain
- 📸 Easy image management
- 🚀 Better scalability
- 🔧 Easier debugging

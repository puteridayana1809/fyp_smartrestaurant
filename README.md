<<<<<<< HEAD
# Bihun Sup Daging Selambak - POS System

Restaurant Point of Sale system built with HTML, JavaScript, and Firebase.

## Setup Instructions

### 1. Firebase Configuration

This project requires Firebase. The API keys are **not included** in the repository for security.

**To set up Firebase:**

1. Copy the template file:
   ```bash
   cp js/firebase-config.example.js js/firebase-config.esm.js
   ```

2. Edit `js/firebase-config.esm.js` and fill in your Firebase config:
   ```javascript
   export const firebaseConfig = {
     apiKey: "YOUR_API_KEY_HERE",
     authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
     projectId: "YOUR_PROJECT_ID",
     storageBucket: "YOUR_PROJECT_ID.firebasestorage.app",
     messagingSenderId: "YOUR_SENDER_ID",
     appId: "YOUR_APP_ID",
     measurementId: "YOUR_MEASUREMENT_ID"
   };
   ```

3. You can get these values from your [Firebase Console](https://console.firebase.google.com/) > Project Settings > General > Your apps > Web app

### 2. Running the Project

Since this is a static HTML project with ES modules, you need to serve it via HTTP (not file://):

```bash
# Option 1: Use Python
python -m http.server 8000

# Option 2: Use Node.js http-server
npx http-server

# Option 3: Use VS Code Live Server extension
```

Then open http://localhost:8000 in your browser.

## Project Structure

```
public/
├── index.html              # Login page
├── admin.html              # Admin dashboard
├── reception.html          # Cashier/Payment page
├── order.html              # Waiter order page
├── kds.html                # Kitchen display system
├── js/
│   ├── firebase-config.esm.js     # Your Firebase config (gitignored)
│   └── firebase-config.example.js # Template (committed)
└── dashboard-admin/
    ├── tablemanagement.html
    ├── menumanager.html
    ├── staffmanagement.html
    └── groceriesmanagement.html
```

## Pages

- **Login** (`index.html`) - Staff login with role-based routing
- **Admin Dashboard** (`admin.html`) - Sales overview, charts, KPIs
- **Cashier** (`reception.html`) - Process payments, view pending orders
- **Waiter** (`order.html`) - Take orders, select tables
- **Kitchen** (`kds.html`) - View and manage cooking orders

## Security

⚠️ **Important**: Never commit `firebase-config.esm.js` or `firebase-config.js` to Git. These files contain your API keys and are excluded via `.gitignore`.
=======
# fyp_smartrestaurant
pos system kedai bihun sup daging selambak
>>>>>>> 1d65439fe63ac21ba0036595c5c62c56dc60a3ed

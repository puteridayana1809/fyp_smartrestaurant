# Firebase Storage CORS Fix

## Problem
Getting CORS errors when uploading images to Firebase Storage from localhost.

## Solution

### Method 1: Update Firebase Storage Rules (Recommended)

1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: `kedai-bihun-selambak`
3. Go to **Storage** > **Rules**
4. Replace the rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /restaurants/{restaurantId}/{allPaths=**} {
      // Allow authenticated users to read
      allow read: if request.auth != null;
      
      // Allow authenticated users to write to their restaurant's menu-images
      allow write: if request.auth != null && 
                     allPaths.matches('menu-images/.*');
    }
  }
}
```

5. Click **Publish**

### Method 2: Configure CORS via Google Cloud Console

1. Go to: https://console.cloud.google.com
2. Select project: `kedai-bihun-selambak`
3. Open Cloud Shell (top right icon)
4. Create a file `cors.json`:

```bash
echo '[
  {
    "origin": ["http://localhost:5500", "http://127.0.0.1:5500", "http://localhost:5501"],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "maxAgeSeconds": 3600
  }
]' > cors.json
```

5. Apply CORS configuration:

```bash
gsutil cors set cors.json gs://kedai-bihun-selambak.appspot.com
```

### Method 3: Use Firebase Hosting (Best for Production)

Instead of running on localhost, deploy to Firebase Hosting which has proper CORS:

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy --only hosting
```

## Quick Test

After applying any method above, refresh your page and try uploading again. The CORS error should be resolved.

## Notes

- Method 1 is quickest and works for authenticated users
- Method 2 gives more control over CORS origins
- Method 3 is best for production deployment
- Current code already uses `uploadBytesResumable` with proper metadata for better upload handling

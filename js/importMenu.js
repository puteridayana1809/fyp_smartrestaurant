// importMenu.js (CommonJS)
// Run: node importMenu.js  (from C:\Users\luqma\public\js)

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");
const csv = require("csv-parser");

// ---- CONFIG ----
const restaurantId = "kedai_makan";                // MUST match your web app
const csvPath = path.join(__dirname, "menu.csv");  // CSV file in same folder
const validCats = ["drinking", "goreng2", "sup"];  // allowed categories

// Load admin key (DO NOT DEPLOY THIS FILE)
const serviceAccount = require(path.join(__dirname, "serviceAccountKey.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// Helpers
function toNumber(x) {
  if (x === undefined || x === null) return NaN;
  const n = parseFloat(String(x).replace(/[^\d.]/g, ""));
  return Number.isNaN(n) ? NaN : n;
}

async function importMenu() {
  if (!fs.existsSync(csvPath)) {
    console.error("❌ CSV not found:", csvPath);
    process.exit(1);
  }

  console.log("⏳ Importing menu from:", csvPath);

  let total = 0, ok = 0, bad = 0;
  const writes = [];

  await new Promise((resolve, reject) => {
    fs.createReadStream(csvPath)
      .pipe(csv()) // expects headers: name,categoryId,price_rm
      .on("data", (row) => {
        total++;

        const name = String(row.name || "").trim();
        const categoryId = String(row.categoryId || "").trim().toLowerCase();
        const price = toNumber(row.price_rm);

        if (!name || !validCats.includes(categoryId) || Number.isNaN(price)) {
          bad++;
          console.warn("⚠️  Skipping invalid row:", row);
          return;
        }

        const colRef = db.collection("restaurants")
                         .doc(restaurantId)
                         .collection("menuItems");

        const p = colRef.add({
          name,
          categoryId,
          price,
          isAvailable: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        })
        .then(() => { ok++; console.log("✅ Added:", name); })
        .catch(err => { bad++; console.error("❌ Error adding", name, err.message); });

        writes.push(p);
      })
      .on("end", resolve)
      .on("error", reject);
  });

  await Promise.all(writes);
  console.log(`🚀 Menu import complete. rows=${total}, added=${ok}, skipped/errors=${bad}`);
}

importMenu().then(() => {
  console.log("🎉 All done.");
  process.exit(0);
}).catch(err => {
  console.error("❌ Fatal:", err);
  process.exit(1);
});

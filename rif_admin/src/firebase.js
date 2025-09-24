// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { getStorage } from "firebase/storage";

// Your web app's Firebase configuration
// For Firebase JS SDK v9-compat and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyD1bE-_VpZigPtu2kYw9ol0dnLh3gZzQoI",
  authDomain: "rifuniv.firebaseapp.com",
  projectId: "rifuniv",
  storageBucket: "rifuniv.firebasestorage.app",
  messagingSenderId: "728410557347",
  appId: "1:728410557347:web:60f966556bcc7005ece816",
  measurementId: "G-K3Q4EPG3QN",
};

// Initialize Firebase
console.log("Initializing Firebase for admin panel...");
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const db = getFirestore(app);
export const auth = getAuth(app);
export const storage = getStorage(app);

// Test Firebase connection
const testFirebaseConnection = async () => {
  try {
    console.log("Testing Firestore connection...");
    // Try to read from a test collection (won't create if it doesn't exist)
    const { getDocs, collection, limit, query } = await import(
      "firebase/firestore"
    );
    const testQuery = query(collection(db, "test"), limit(1));
    await getDocs(testQuery);
    console.log("✅ Firestore connection successful");
  } catch (error) {
    console.error("❌ Firestore connection failed:", error);
    console.error("Error code:", error.code);
    console.error("Error message:", error.message);
  }

  try {
    console.log("Testing Firebase Storage connection...");
    const { ref, listAll } = await import("firebase/storage");
    const storageRef = ref(storage, "keynote-speakers");

    // Test storage access with list operation
    await listAll(storageRef);
    console.log("✅ Firebase Storage connection and access successful");
    console.log("✅ Storage bucket accessible:", firebaseConfig.storageBucket);
  } catch (error) {
    console.error("❌ Firebase Storage connection failed:", error);
    console.error("Error code:", error.code);
    console.error("Error message:", error.message);

    if (error.code === "storage/unauthorized") {
      console.error(
        "🔥 SOLUTION: Update Firebase Storage security rules to allow read/write access"
      );
      console.error(
        "🔥 Go to Firebase Console → Storage → Rules and set appropriate permissions"
      );
    }
  }
};

// Run connection test
testFirebaseConnection();

console.log("Firebase admin initialized successfully");
console.log("Project ID:", firebaseConfig.projectId);
console.log("Storage Bucket:", firebaseConfig.storageBucket);

export default app;

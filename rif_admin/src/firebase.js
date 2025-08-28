// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

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

console.log("Firebase admin initialized successfully");
console.log("Project ID:", firebaseConfig.projectId);

export default app;

// Firebase Connection Test - Run this in browser console if needed
import { db, storage } from "./firebase.js";
import {
  collection,
  addDoc,
  getDocs,
  deleteDoc,
  doc,
} from "firebase/firestore";
import {
  ref,
  uploadBytes,
  getDownloadURL,
  deleteObject,
} from "firebase/storage";

export const testFirebaseOperations = async () => {
  console.log("🔬 Starting comprehensive Firebase tests...");

  try {
    // Test 1: Basic Firestore Connection
    console.log("📡 Test 1: Testing Firestore connection...");
    const testCollection = collection(db, "connection_test");
    const testData = {
      message: "Connection test",
      timestamp: new Date().toISOString(),
      testId: Math.random().toString(36).substr(2, 9),
    };

    const docRef = await addDoc(testCollection, testData);
    console.log("✅ Test 1 PASSED: Document created with ID:", docRef.id);

    // Test 2: Read from Firestore
    console.log("📖 Test 2: Testing Firestore read...");
    const querySnapshot = await getDocs(testCollection);
    console.log("✅ Test 2 PASSED: Found", querySnapshot.size, "documents");

    // Test 3: Delete test document (cleanup)
    console.log("🗑️ Test 3: Cleaning up test document...");
    await deleteDoc(doc(db, "connection_test", docRef.id));
    console.log("✅ Test 3 PASSED: Test document deleted");

    // Test 4: Test Storage (create a tiny test file)
    console.log("💾 Test 4: Testing Firebase Storage...");
    const testFile = new Blob(["test"], { type: "text/plain" });
    const storageRef = ref(storage, "test/connection-test.txt");

    const snapshot = await uploadBytes(storageRef, testFile);
    console.log("✅ Test 4a PASSED: File uploaded to storage");

    const downloadURL = await getDownloadURL(snapshot.ref);
    console.log("✅ Test 4b PASSED: Download URL obtained:", downloadURL);

    // Test 5: Delete test file (cleanup)
    console.log("🗑️ Test 5: Cleaning up test file...");
    await deleteObject(storageRef);
    console.log("✅ Test 5 PASSED: Test file deleted");

    console.log("🎉 ALL TESTS PASSED: Firebase is working correctly!");
    return { success: true, message: "All Firebase operations working" };
  } catch (error) {
    console.error("❌ FIREBASE TEST FAILED:", error);
    console.error("Error details:", {
      code: error.code,
      message: error.message,
      stack: error.stack,
    });

    // Check specific error types
    if (error.code === "permission-denied") {
      console.error(
        "🚫 PERMISSION ISSUE: Check Firestore/Storage security rules"
      );
    } else if (error.code === "unavailable") {
      console.error(
        "🌐 NETWORK ISSUE: Check internet connection and Firebase project status"
      );
    } else if (error.code === "not-found") {
      console.error(
        "🔍 NOT FOUND: Check if Firebase project exists and config is correct"
      );
    }

    return { success: false, error: error.message };
  }
};

// Test specifically for keynote speakers operations
export const testKeynoteOperations = async () => {
  console.log("🎤 Testing keynote speakers specific operations...");

  try {
    // Test adding a keynote speaker
    const testSpeaker = {
      name: "Test Speaker",
      title: "Test Title",
      institution: "Test Institution",
      biography: "Test biography",
      order: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    console.log("➕ Adding test keynote speaker...");
    const docRef = await addDoc(
      collection(db, "keynote_speakers"),
      testSpeaker
    );
    console.log("✅ Test speaker added with ID:", docRef.id);

    // Test reading keynote speakers
    console.log("📖 Reading keynote speakers...");
    const querySnapshot = await getDocs(collection(db, "keynote_speakers"));
    console.log("✅ Found", querySnapshot.size, "keynote speakers");

    // Clean up test speaker
    console.log("🗑️ Cleaning up test speaker...");
    await deleteDoc(doc(db, "keynote_speakers", docRef.id));
    console.log("✅ Test speaker deleted");

    console.log("🎉 KEYNOTE OPERATIONS TEST PASSED!");
    return { success: true };
  } catch (error) {
    console.error("❌ KEYNOTE OPERATIONS TEST FAILED:", error);
    return { success: false, error: error.message };
  }
};

// Auto-run tests when this module loads
if (typeof window !== "undefined") {
  // Only run in browser environment
  console.log(
    "🚀 Firebase tests available. Run testFirebaseOperations() or testKeynoteOperations() in console"
  );
  // Make functions available globally for console testing
  window.testFirebaseOperations = testFirebaseOperations;
  window.testKeynoteOperations = testKeynoteOperations;
}

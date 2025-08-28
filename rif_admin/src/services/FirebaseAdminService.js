import {
  collection,
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  getDocs,
  query,
  orderBy,
  serverTimestamp,
  enableNetwork,
} from "firebase/firestore";
import { db } from "../firebase.js";

class FirebaseAdminService {
  static programsCollection = collection(db, "programs");
  static isOnline = true;

  // Initialize Firebase connection
  static async initialize() {
    try {
      console.log("Initializing Firebase Admin Service...");
      // Test connection
      await this.testConnection();
      this.isOnline = true;
      console.log("Firebase connection established");
    } catch (error) {
      console.error("Firebase connection failed:", error);
      this.isOnline = false;
    }
  }

  // Test Firebase connection
  static async testConnection() {
    try {
      const testQuery = query(this.programsCollection);
      await getDocs(testQuery);
      return true;
    } catch (error) {
      console.error("Connection test failed:", error);
      throw error;
    }
  }

  // Get all programs
  static async getPrograms() {
    try {
      console.log("Fetching programs from Firebase...");

      // Check connection first
      if (!this.isOnline) {
        await this.initialize();
      }

      const q = query(this.programsCollection, orderBy("date", "asc"));
      const querySnapshot = await getDocs(q);

      const programs = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      console.log(`Successfully fetched ${programs.length} programs`);
      return programs;
    } catch (error) {
      console.error("Error fetching programs:", error);

      // If it's a permission error, provide helpful message
      if (error.code === "permission-denied") {
        console.error(
          "Permission denied. Please check Firestore security rules."
        );
        throw new Error(
          "Access denied. Please check Firebase security configuration."
        );
      }

      // If it's a network error, try to reconnect
      if (error.code === "unavailable") {
        console.log("Network unavailable, attempting to reconnect...");
        try {
          await enableNetwork(db);
          this.isOnline = true;
          return await this.getPrograms(); // Retry once
        } catch (reconnectError) {
          console.error("Reconnection failed:", reconnectError);
        }
      }

      return [];
    }
  }

  // Add a new program
  static async addProgram(programData) {
    try {
      console.log("Adding program to Firebase:", programData.title);

      if (!this.isOnline) {
        await this.initialize();
      }

      const docRef = await addDoc(this.programsCollection, {
        ...programData,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });

      console.log("Program added with ID:", docRef.id);

      // Return the full program object with the new ID
      return {
        id: docRef.id,
        ...programData,
      };
    } catch (error) {
      console.error("Error adding program:", error);

      if (error.code === "permission-denied") {
        throw new Error(
          "Permission denied. Please check Firebase security rules."
        );
      }

      throw new Error(error.message || "Failed to add program");
    }
  }

  // Update an existing program
  static async updateProgram(programId, programData) {
    try {
      console.log("Updating program:", programId);

      if (!this.isOnline) {
        await this.initialize();
      }

      const programRef = doc(db, "programs", programId);
      await updateDoc(programRef, {
        ...programData,
        updatedAt: serverTimestamp(),
      });

      console.log("Program updated successfully:", programId);
      return true; // Just return true for success
    } catch (error) {
      console.error("Error updating program:", error);

      if (error.code === "permission-denied") {
        throw new Error(
          "Permission denied. Please check Firebase security rules."
        );
      }

      throw new Error(error.message || "Failed to update program");
    }
  }

  // Delete a program
  static async deleteProgram(programId) {
    try {
      console.log("Deleting program:", programId);

      if (!this.isOnline) {
        await this.initialize();
      }

      const programRef = doc(db, "programs", programId);
      await deleteDoc(programRef);

      console.log("Program deleted successfully:", programId);
      return true; // Just return true for success
    } catch (error) {
      console.error("Error deleting program:", error);

      if (error.code === "permission-denied") {
        throw new Error(
          "Permission denied. Please check Firebase security rules."
        );
      }

      throw new Error(error.message || "Failed to delete program");
    }
  }

  // Convert program data for Firebase storage
  static formatProgramForFirebase(formData) {
    let conferences = [...formData.conferences];

    // If keynoteHasConference, ensure the keynote's conference is the first in the list
    if (formData.keynoteHasConference) {
      const keynoteConf = {
        title:
          formData.keynoteConference.title ||
          `${formData.keynote.name} (Keynote)`,
        presenter: formData.keynote.name,
        affiliation: formData.keynote.affiliation,
        start: formData.keynoteConference.start,
        end: formData.keynoteConference.end,
        isKeynote: true,
        resume: formData.keynoteDescription || "",
      };

      // Replace or add as first conference
      if (conferences.length > 0 && conferences[0].isKeynote) {
        conferences[0] = keynoteConf;
      } else {
        conferences = [keynoteConf, ...conferences];
      }
    } else {
      // Remove keynote conference if unchecked
      if (conferences.length > 0 && conferences[0].isKeynote) {
        conferences = conferences.slice(1);
      }
    }

    return {
      type: formData.type || "session",
      title: formData.title,
      date: formData.date,
      start: formData.start,
      end: formData.end,
      chairs: formData.chairs,
      keynote: formData.keynote,
      keynoteDescription: formData.keynoteDescription,
      conferences: conferences,
    };
  }
}

export default FirebaseAdminService;

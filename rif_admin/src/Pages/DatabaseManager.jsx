import React, { useState } from "react";
import { collection, getDocs, deleteDoc, doc } from "firebase/firestore";
import { db } from "../firebase";
import "../styles/database.css";

const DatabaseManager = () => {
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");
  const [confirmNotifications, setConfirmNotifications] = useState("");
  const [confirmPrograms, setConfirmPrograms] = useState("");
  const [confirmRatings, setConfirmRatings] = useState("");
  const [confirmAnalytics, setConfirmAnalytics] = useState("");
  const [confirmQuestions, setConfirmQuestions] = useState("");
  const [confirmLiveNotifications, setConfirmLiveNotifications] = useState("");
  const [confirmPushNotifications, setConfirmPushNotifications] = useState("");
  const [confirmAllData, setConfirmAllData] = useState("");
  const [stats, setStats] = useState({
    notifications: 0,
    programs: 0,
    ratings: 0,
    presentationAnalytics: 0,
    questions: 0,
    liveNotifications: 0,
    pushNotifications: 0,
    users: 0,
    userProfiles: 0,
  });

  // Get collection statistics
  const getCollectionStats = async () => {
    try {
      setLoading(true);
      setStatus("Fetching collection statistics...");

      // Count notifications
      const notificationsRef = collection(db, "notifications");
      const notificationsSnapshot = await getDocs(notificationsRef);

      // Count programs
      const programsRef = collection(db, "programs");
      const programsSnapshot = await getDocs(programsRef);

      // Count ratings
      const ratingsRef = collection(db, "ratings");
      const ratingsSnapshot = await getDocs(ratingsRef);

      // Count presentation analytics
      const analyticsRef = collection(db, "presentation_analytics");
      const analyticsSnapshot = await getDocs(analyticsRef);

      // Count questions
      const questionsRef = collection(db, "questions");
      const questionsSnapshot = await getDocs(questionsRef);

      // Count live notifications
      const liveNotificationsRef = collection(db, "live_notifications");
      const liveNotificationsSnapshot = await getDocs(liveNotificationsRef);

      // Count push notifications
      const pushNotificationsRef = collection(db, "push_notifications");
      const pushNotificationsSnapshot = await getDocs(pushNotificationsRef);

      // Count users (for display only - cannot delete)
      const usersRef = collection(db, "users");
      const usersSnapshot = await getDocs(usersRef);

      // Count user profiles (for display only - cannot delete)
      const userProfilesRef = collection(db, "user_profiles");
      const userProfilesSnapshot = await getDocs(userProfilesRef);

      setStats({
        notifications: notificationsSnapshot.size,
        programs: programsSnapshot.size,
        ratings: ratingsSnapshot.size,
        presentationAnalytics: analyticsSnapshot.size,
        questions: questionsSnapshot.size,
        liveNotifications: liveNotificationsSnapshot.size,
        pushNotifications: pushNotificationsSnapshot.size,
        users: usersSnapshot.size,
        userProfiles: userProfilesSnapshot.size,
      });

      setStatus("Statistics loaded successfully");
      setLoading(false);
    } catch (error) {
      console.error("Error fetching stats:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Clear notifications collection
  const clearNotifications = async () => {
    if (confirmNotifications !== "CLEAR_NOTIFICATIONS") {
      setStatus("Please type 'CLEAR_NOTIFICATIONS' to confirm");
      return;
    }

    try {
      setLoading(true);
      setStatus("Clearing notifications collection...");

      const notificationsRef = collection(db, "notifications");
      const snapshot = await getDocs(notificationsRef);

      const deletePromises = snapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "notifications", docSnapshot.id))
      );

      await Promise.all(deletePromises);

      setStatus(`Successfully deleted ${snapshot.size} notification documents`);
      setConfirmNotifications("");
      await getCollectionStats(); // Refresh stats
      setLoading(false);
    } catch (error) {
      console.error("Error clearing notifications:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Clear programs collection
  const clearPrograms = async () => {
    if (confirmPrograms !== "CLEAR_PROGRAMS") {
      setStatus("Please type 'CLEAR_PROGRAMS' to confirm");
      return;
    }

    try {
      setLoading(true);
      setStatus("Clearing programs collection...");

      const programsRef = collection(db, "programs");
      const snapshot = await getDocs(programsRef);

      const deletePromises = snapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "programs", docSnapshot.id))
      );

      await Promise.all(deletePromises);

      setStatus(`Successfully deleted ${snapshot.size} program documents`);
      setConfirmPrograms("");
      await getCollectionStats(); // Refresh stats
      setLoading(false);
    } catch (error) {
      console.error("Error clearing programs:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Clear ratings collection
  const clearRatings = async () => {
    if (confirmRatings !== "CLEAR_RATINGS") {
      setStatus("Please type 'CLEAR_RATINGS' to confirm");
      return;
    }

    try {
      setLoading(true);
      setStatus("Clearing ratings collection...");

      const ratingsRef = collection(db, "ratings");
      const snapshot = await getDocs(ratingsRef);

      const deletePromises = snapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "ratings", docSnapshot.id))
      );

      await Promise.all(deletePromises);

      setStatus(`Successfully deleted ${snapshot.size} rating documents`);
      setConfirmRatings("");
      await getCollectionStats(); // Refresh stats
      setLoading(false);
    } catch (error) {
      console.error("Error clearing ratings:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Clear presentation analytics collection
  const clearAnalytics = async () => {
    if (confirmAnalytics !== "CLEAR_ANALYTICS") {
      setStatus("Please type 'CLEAR_ANALYTICS' to confirm");
      return;
    }

    try {
      setLoading(true);
      setStatus("Clearing presentation analytics collection...");

      const analyticsRef = collection(db, "presentation_analytics");
      const snapshot = await getDocs(analyticsRef);

      const deletePromises = snapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "presentation_analytics", docSnapshot.id))
      );

      await Promise.all(deletePromises);

      setStatus(`Successfully deleted ${snapshot.size} analytics documents`);
      setConfirmAnalytics("");
      await getCollectionStats(); // Refresh stats
      setLoading(false);
    } catch (error) {
      console.error("Error clearing analytics:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Clear questions collection
  const clearQuestions = async () => {
    if (confirmQuestions !== "CLEAR_QUESTIONS") {
      setStatus("Please type 'CLEAR_QUESTIONS' to confirm");
      return;
    }

    try {
      setLoading(true);
      setStatus("Clearing questions collection...");

      const questionsRef = collection(db, "questions");
      const snapshot = await getDocs(questionsRef);

      const deletePromises = snapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "questions", docSnapshot.id))
      );

      await Promise.all(deletePromises);

      setStatus(`Successfully deleted ${snapshot.size} question documents`);
      setConfirmQuestions("");
      await getCollectionStats(); // Refresh stats
      setLoading(false);
    } catch (error) {
      console.error("Error clearing questions:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Clear live notifications collection
  const clearLiveNotifications = async () => {
    if (confirmLiveNotifications !== "CLEAR_LIVE_NOTIFICATIONS") {
      setStatus("Please type 'CLEAR_LIVE_NOTIFICATIONS' to confirm");
      return;
    }

    try {
      setLoading(true);
      setStatus("Clearing live notifications collection...");

      const liveNotificationsRef = collection(db, "live_notifications");
      const snapshot = await getDocs(liveNotificationsRef);

      const deletePromises = snapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "live_notifications", docSnapshot.id))
      );

      await Promise.all(deletePromises);

      setStatus(
        `Successfully deleted ${snapshot.size} live notification documents`
      );
      setConfirmLiveNotifications("");
      await getCollectionStats(); // Refresh stats
      setLoading(false);
    } catch (error) {
      console.error("Error clearing live notifications:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Clear push notifications collection
  const clearPushNotifications = async () => {
    if (confirmPushNotifications !== "CLEAR_PUSH_NOTIFICATIONS") {
      setStatus("Please type 'CLEAR_PUSH_NOTIFICATIONS' to confirm");
      return;
    }

    try {
      setLoading(true);
      setStatus("Clearing push notifications collection...");

      const pushNotificationsRef = collection(db, "push_notifications");
      const snapshot = await getDocs(pushNotificationsRef);

      const deletePromises = snapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "push_notifications", docSnapshot.id))
      );

      await Promise.all(deletePromises);

      setStatus(
        `Successfully deleted ${snapshot.size} push notification documents`
      );
      setConfirmPushNotifications("");
      await getCollectionStats(); // Refresh stats
      setLoading(false);
    } catch (error) {
      console.error("Error clearing push notifications:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Clear all data (notifications + programs + ratings + analytics + questions + live_notifications + push_notifications)
  const clearAllData = async () => {
    if (confirmAllData !== "CLEAR_ALL_DATA") {
      setStatus("Please type 'CLEAR_ALL_DATA' to confirm");
      return;
    }

    try {
      setLoading(true);
      setStatus("Clearing all conference data...");

      // Clear notifications
      const notificationsRef = collection(db, "notifications");
      const notificationsSnapshot = await getDocs(notificationsRef);
      const notificationDeletes = notificationsSnapshot.docs.map(
        (docSnapshot) => deleteDoc(doc(db, "notifications", docSnapshot.id))
      );

      // Clear programs
      const programsRef = collection(db, "programs");
      const programsSnapshot = await getDocs(programsRef);
      const programDeletes = programsSnapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "programs", docSnapshot.id))
      );

      // Clear ratings
      const ratingsRef = collection(db, "ratings");
      const ratingsSnapshot = await getDocs(ratingsRef);
      const ratingDeletes = ratingsSnapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "ratings", docSnapshot.id))
      );

      // Clear presentation analytics
      const analyticsRef = collection(db, "presentation_analytics");
      const analyticsSnapshot = await getDocs(analyticsRef);
      const analyticsDeletes = analyticsSnapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "presentation_analytics", docSnapshot.id))
      );

      // Clear questions
      const questionsRef = collection(db, "questions");
      const questionsSnapshot = await getDocs(questionsRef);
      const questionDeletes = questionsSnapshot.docs.map((docSnapshot) =>
        deleteDoc(doc(db, "questions", docSnapshot.id))
      );

      // Clear live notifications
      const liveNotificationsRef = collection(db, "live_notifications");
      const liveNotificationsSnapshot = await getDocs(liveNotificationsRef);
      const liveNotificationDeletes = liveNotificationsSnapshot.docs.map(
        (docSnapshot) =>
          deleteDoc(doc(db, "live_notifications", docSnapshot.id))
      );

      // Clear push notifications
      const pushNotificationsRef = collection(db, "push_notifications");
      const pushNotificationsSnapshot = await getDocs(pushNotificationsRef);
      const pushNotificationDeletes = pushNotificationsSnapshot.docs.map(
        (docSnapshot) =>
          deleteDoc(doc(db, "push_notifications", docSnapshot.id))
      );

      // Execute all deletes
      await Promise.all([
        ...notificationDeletes,
        ...programDeletes,
        ...ratingDeletes,
        ...analyticsDeletes,
        ...questionDeletes,
        ...liveNotificationDeletes,
        ...pushNotificationDeletes,
      ]);

      const totalDeleted =
        notificationsSnapshot.size +
        programsSnapshot.size +
        ratingsSnapshot.size +
        analyticsSnapshot.size +
        questionsSnapshot.size +
        liveNotificationsSnapshot.size +
        pushNotificationsSnapshot.size;
      setStatus(
        `Successfully cleared all conference data: ${totalDeleted} documents deleted`
      );
      setConfirmAllData("");
      await getCollectionStats(); // Refresh stats
      setLoading(false);
    } catch (error) {
      console.error("Error clearing all data:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Export functions
  const exportToJSON = (data, filename) => {
    const jsonData = JSON.stringify(data, null, 2);
    const blob = new Blob([jsonData], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${filename}_${new Date().toISOString().split("T")[0]}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const exportToCSV = (data, filename) => {
    if (!data || data.length === 0) {
      setStatus("No data to export");
      return;
    }

    // Function to convert Firebase timestamp to readable date
    const formatDate = (timestamp) => {
      if (!timestamp) return "";

      if (timestamp.seconds) {
        // Firebase Timestamp
        return new Date(timestamp.seconds * 1000).toLocaleString();
      } else if (timestamp instanceof Date) {
        return timestamp.toLocaleString();
      } else if (typeof timestamp === "string") {
        return new Date(timestamp).toLocaleString();
      }
      return timestamp;
    };

    // Collection-specific formatting
    const formatDataForCollection = (data, filename) => {
      switch (filename) {
        case "notifications":
        case "all_notifications":
          return data.map((item) => ({
            ID: item.id || "",
            Title: item.title || "",
            Message: item.body || item.message || "",
            Type: item.type || "",
            Created: formatDate(item.timestamp || item.createdAt),
            Sent: item.sent ? "Yes" : "No",
            Topic: item.topic || "",
          }));

        case "programs":
        case "all_programs":
          return data.map((item) => ({
            ID: item.id || "",
            Title: item.title || "",
            Speaker: item.speaker || item.presenter || "",
            Date: formatDate(item.date),
            "Start Time": item.startTime || "",
            "End Time": item.endTime || "",
            Location: item.location || item.room || "",
            Description: item.description || "",
            Status: item.status || "",
          }));

        case "ratings":
        case "all_ratings":
          return data.map((item) => ({
            ID: item.id || "",
            "Program ID": item.programId || "",
            "User ID": item.userId || "",
            Rating: item.rating || "",
            Comment: item.comment || "",
            Created: formatDate(item.timestamp || item.createdAt),
          }));

        case "presentation_analytics":
        case "all_analytics":
          return data.map((item) => ({
            ID: item.id || "",
            "Program ID": item.programId || "",
            Views: item.views || 0,
            Downloads: item.downloads || 0,
            Shares: item.shares || 0,
            "Average Rating": item.averageRating || "",
            "Total Ratings": item.totalRatings || 0,
            "Last Updated": formatDate(item.lastUpdated),
          }));

        case "questions":
        case "all_questions":
          return data.map((item) => ({
            ID: item.id || "",
            "Program ID": item.programId || "",
            "User ID": item.userId || "",
            Question: item.question || item.message || "",
            Answer: item.answer || "",
            Status: item.status || "",
            Asked: formatDate(item.timestamp || item.createdAt),
            Answered: formatDate(item.answeredAt),
          }));

        case "live_notifications":
        case "all_live_notifications":
          return data.map((item) => ({
            ID: item.id || "",
            Title: item.title || "",
            Message: item.body || item.message || "",
            Type: item.type || "",
            Processed: item.processed ? "Yes" : "No",
            Created: formatDate(item.timestamp),
          }));

        case "push_notifications":
        case "all_push_notifications":
          return data.map((item) => ({
            ID: item.id || "",
            Title: item.title || "",
            Message: item.body || "",
            Topic: item.topic || "",
            Sent: item.sent ? "Yes" : "No",
            Created: formatDate(item.timestamp),
          }));

        case "users":
        case "all_users":
          return data.map((item) => ({
            ID: item.id || "",
            Email: item.email || "",
            "Display Name": item.displayName || item.name || "",
            Role: item.role || "",
            Created: formatDate(item.createdAt),
            "Last Login": formatDate(item.lastLogin),
            "FCM Token": item.fcmToken ? "Yes" : "No",
          }));

        case "user_profiles":
        case "all_user_profiles":
          return data.map((item) => ({
            ID: item.id || "",
            "User ID": item.userId || "",
            "Full Name": item.fullName || item.name || "",
            Organization: item.organization || "",
            Position: item.position || item.title || "",
            Bio: item.bio || "",
            Phone: item.phone || "",
            Updated: formatDate(item.updatedAt),
          }));

        default:
          // Generic format for any other collection
          return data.map((item) => {
            const formatted = {};
            Object.keys(item).forEach((key) => {
              if (key === "id") {
                formatted["ID"] = item[key];
              } else if (
                key.toLowerCase().includes("time") ||
                key.toLowerCase().includes("date") ||
                key === "timestamp" ||
                key === "createdAt" ||
                key === "updatedAt"
              ) {
                formatted[key.charAt(0).toUpperCase() + key.slice(1)] =
                  formatDate(item[key]);
              } else if (typeof item[key] === "boolean") {
                formatted[key.charAt(0).toUpperCase() + key.slice(1)] = item[
                  key
                ]
                  ? "Yes"
                  : "No";
              } else if (typeof item[key] === "object" && item[key] !== null) {
                formatted[key.charAt(0).toUpperCase() + key.slice(1)] =
                  JSON.stringify(item[key]);
              } else {
                formatted[key.charAt(0).toUpperCase() + key.slice(1)] =
                  item[key] || "";
              }
            });
            return formatted;
          });
      }
    };

    // Format data based on collection type
    const formattedData = formatDataForCollection(data, filename);

    // Get column headers
    const headers = Object.keys(formattedData[0] || {});

    // Create CSV content
    const csvHeader = headers.join(",");
    const csvRows = formattedData.map((row) => {
      return headers
        .map((header) => {
          const value = row[header] || "";
          // Escape quotes and wrap in quotes if contains commas
          if (
            typeof value === "string" &&
            (value.includes(",") || value.includes('"') || value.includes("\n"))
          ) {
            return `"${value.replace(/"/g, '""')}"`;
          }
          return value;
        })
        .join(",");
    });

    const csvContent = [csvHeader, ...csvRows].join("\n");

    // Add UTF-8 BOM for Excel compatibility
    const BOM = "\uFEFF";
    const blob = new Blob([BOM + csvContent], {
      type: "text/csv;charset=utf-8;",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${filename}_${new Date().toISOString().split("T")[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  // Export notifications data
  const exportNotifications = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting notifications data...");

      const notificationsRef = collection(db, "notifications");
      const snapshot = await getDocs(notificationsRef);

      const data = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        exportedAt: new Date().toISOString(),
      }));

      if (format === "csv") {
        exportToCSV(data, "notifications");
      } else {
        exportToJSON(data, "notifications");
      }

      setStatus(
        `Successfully exported ${
          data.length
        } notifications as ${format.toUpperCase()}`
      );
      setLoading(false);
    } catch (error) {
      console.error("Error exporting notifications:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Export programs data
  const exportPrograms = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting programs data...");

      const programsRef = collection(db, "programs");
      const snapshot = await getDocs(programsRef);

      const data = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        exportedAt: new Date().toISOString(),
      }));

      if (format === "csv") {
        exportToCSV(data, "programs");
      } else {
        exportToJSON(data, "programs");
      }

      setStatus(
        `Successfully exported ${
          data.length
        } programs as ${format.toUpperCase()}`
      );
      setLoading(false);
    } catch (error) {
      console.error("Error exporting programs:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Export ratings data
  const exportRatings = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting ratings data...");

      const ratingsRef = collection(db, "ratings");
      const snapshot = await getDocs(ratingsRef);

      const data = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        exportedAt: new Date().toISOString(),
      }));

      if (format === "csv") {
        exportToCSV(data, "ratings");
      } else {
        exportToJSON(data, "ratings");
      }

      setStatus(
        `Successfully exported ${
          data.length
        } ratings as ${format.toUpperCase()}`
      );
      setLoading(false);
    } catch (error) {
      console.error("Error exporting ratings:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Export presentation analytics data
  const exportAnalytics = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting presentation analytics data...");

      const analyticsRef = collection(db, "presentation_analytics");
      const snapshot = await getDocs(analyticsRef);

      const data = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        exportedAt: new Date().toISOString(),
      }));

      if (format === "csv") {
        exportToCSV(data, "presentation_analytics");
      } else {
        exportToJSON(data, "presentation_analytics");
      }

      setStatus(
        `Successfully exported ${
          data.length
        } analytics records as ${format.toUpperCase()}`
      );
      setLoading(false);
    } catch (error) {
      console.error("Error exporting analytics:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Export users data (for reference only)
  const exportUsers = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting users data...");

      const usersRef = collection(db, "users");
      const snapshot = await getDocs(usersRef);

      const data = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        exportedAt: new Date().toISOString(),
      }));

      if (format === "csv") {
        exportToCSV(data, "users");
      } else {
        exportToJSON(data, "users");
      }

      setStatus(
        `Successfully exported ${data.length} users as ${format.toUpperCase()}`
      );
      setLoading(false);
    } catch (error) {
      console.error("Error exporting users:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Export questions data
  const exportQuestions = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting questions data...");

      const questionsRef = collection(db, "questions");
      const snapshot = await getDocs(questionsRef);

      const data = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        exportedAt: new Date().toISOString(),
      }));

      if (format === "csv") {
        exportToCSV(data, "questions");
      } else {
        exportToJSON(data, "questions");
      }

      setStatus(
        `Successfully exported ${
          data.length
        } questions as ${format.toUpperCase()}`
      );
      setLoading(false);
    } catch (error) {
      console.error("Error exporting questions:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Export live notifications data
  const exportLiveNotifications = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting live notifications data...");

      const liveNotificationsRef = collection(db, "live_notifications");
      const snapshot = await getDocs(liveNotificationsRef);

      const data = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        exportedAt: new Date().toISOString(),
      }));

      if (format === "csv") {
        exportToCSV(data, "live_notifications");
      } else {
        exportToJSON(data, "live_notifications");
      }

      setStatus(
        `Successfully exported ${
          data.length
        } live notifications as ${format.toUpperCase()}`
      );
      setLoading(false);
    } catch (error) {
      console.error("Error exporting live notifications:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Export push notifications data
  const exportPushNotifications = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting push notifications data...");

      const pushNotificationsRef = collection(db, "push_notifications");
      const snapshot = await getDocs(pushNotificationsRef);

      const data = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        exportedAt: new Date().toISOString(),
      }));

      if (format === "csv") {
        exportToCSV(data, "push_notifications");
      } else {
        exportToJSON(data, "push_notifications");
      }

      setStatus(
        `Successfully exported ${
          data.length
        } push notifications as ${format.toUpperCase()}`
      );
      setLoading(false);
    } catch (error) {
      console.error("Error exporting push notifications:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Export user profiles data (for reference only)
  const exportUserProfiles = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting user profiles data...");

      const userProfilesRef = collection(db, "user_profiles");
      const snapshot = await getDocs(userProfilesRef);

      const data = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        exportedAt: new Date().toISOString(),
      }));

      if (format === "csv") {
        exportToCSV(data, "user_profiles");
      } else {
        exportToJSON(data, "user_profiles");
      }

      setStatus(
        `Successfully exported ${
          data.length
        } user profiles as ${format.toUpperCase()}`
      );
      setLoading(false);
    } catch (error) {
      console.error("Error exporting user profiles:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  // Export all data
  const exportAllData = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting all data...");

      // Get all collections
      const [
        notificationsSnapshot,
        programsSnapshot,
        ratingsSnapshot,
        analyticsSnapshot,
        questionsSnapshot,
        liveNotificationsSnapshot,
        pushNotificationsSnapshot,
        usersSnapshot,
        userProfilesSnapshot,
      ] = await Promise.all([
        getDocs(collection(db, "notifications")),
        getDocs(collection(db, "programs")),
        getDocs(collection(db, "ratings")),
        getDocs(collection(db, "presentation_analytics")),
        getDocs(collection(db, "questions")),
        getDocs(collection(db, "live_notifications")),
        getDocs(collection(db, "push_notifications")),
        getDocs(collection(db, "users")),
        getDocs(collection(db, "user_profiles")),
      ]);

      const allData = {
        notifications: notificationsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })),
        programs: programsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })),
        ratings: ratingsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })),
        presentation_analytics: analyticsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })),
        questions: questionsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })),
        live_notifications: liveNotificationsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })),
        push_notifications: pushNotificationsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })),
        users: usersSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
        user_profiles: userProfilesSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })),
        exportedAt: new Date().toISOString(),
        exportMetadata: {
          totalNotifications: notificationsSnapshot.size,
          totalPrograms: programsSnapshot.size,
          totalRatings: ratingsSnapshot.size,
          totalAnalytics: analyticsSnapshot.size,
          totalQuestions: questionsSnapshot.size,
          totalLiveNotifications: liveNotificationsSnapshot.size,
          totalPushNotifications: pushNotificationsSnapshot.size,
          totalUsers: usersSnapshot.size,
          totalUserProfiles: userProfilesSnapshot.size,
          exportDate: new Date().toISOString(),
        },
      };

      if (format === "csv") {
        // For CSV, export each collection separately
        exportToCSV(allData.notifications, "all_notifications");
        exportToCSV(allData.programs, "all_programs");
        exportToCSV(allData.ratings, "all_ratings");
        exportToCSV(allData.presentation_analytics, "all_analytics");
        exportToCSV(allData.questions, "all_questions");
        exportToCSV(allData.live_notifications, "all_live_notifications");
        exportToCSV(allData.push_notifications, "all_push_notifications");
        exportToCSV(allData.users, "all_users");
        exportToCSV(allData.user_profiles, "all_user_profiles");
        setStatus(`Successfully exported all data as separate CSV files`);
      } else {
        exportToJSON(allData, "complete_database_backup");
        setStatus(`Successfully exported complete database backup as JSON`);
      }

      setLoading(false);
    } catch (error) {
      console.error("Error exporting all data:", error);
      setStatus(`Error: ${error.message}`);
      setLoading(false);
    }
  };

  React.useEffect(() => {
    getCollectionStats();
  }, []);

  return (
    <div className="database-manager">
      <div className="database-header">
        <h1>🗄️ Database Management</h1>
        <p>
          Safely manage and clear database collections for new conference years
        </p>
      </div>

      {/* Database Statistics */}
      <div className="stats-section">
        <h2>📊 Collection Statistics</h2>
        <div className="stats-grid compact">
          <div className="stat-card">
            <div className="stat-number">{stats.notifications}</div>
            <div className="stat-label">📢 notifications</div>
          </div>
          <div className="stat-card">
            <div className="stat-number">{stats.programs}</div>
            <div className="stat-label">📅 programs</div>
          </div>
          <div className="stat-card">
            <div className="stat-number">{stats.ratings}</div>
            <div className="stat-label">⭐ ratings</div>
          </div>
          <div className="stat-card">
            <div className="stat-number">{stats.presentationAnalytics}</div>
            <div className="stat-label">📊 presentation_analytics</div>
          </div>
          <div className="stat-card">
            <div className="stat-number">{stats.questions}</div>
            <div className="stat-label">❓ questions</div>
          </div>
          <div className="stat-card">
            <div className="stat-number">{stats.liveNotifications}</div>
            <div className="stat-label">🔔 live_notifications</div>
          </div>
          <div className="stat-card">
            <div className="stat-number">{stats.pushNotifications}</div>
            <div className="stat-label">📱 push_notifications</div>
          </div>
          <div className="stat-card preserved">
            <div className="stat-number">{stats.users}</div>
            <div className="stat-label">👥 users</div>
            <div className="stat-note">Protected</div>
          </div>
          <div className="stat-card preserved">
            <div className="stat-number">{stats.userProfiles}</div>
            <div className="stat-label">👤 user_profiles</div>
            <div className="stat-note">Protected</div>
          </div>
        </div>
        <button
          className="refresh-btn compact"
          onClick={getCollectionStats}
          disabled={loading}
        >
          🔄 Refresh
        </button>
      </div>

      {/* Export Section */}
      <div className="export-section">
        <h2>💾 Data Export & Backup</h2>
        <p>
          Export your data before cleaning to create backups. Choose your
          preferred format.
        </p>

        <div className="export-grid">
          {/* Export Notifications */}
          <div className="export-card">
            <h3>📢 Export notifications</h3>
            <p>
              Download all notification history ({stats.notifications}{" "}
              documents)
            </p>
            <div className="export-buttons">
              <button
                className="export-btn json"
                onClick={() => exportNotifications("json")}
                disabled={loading || stats.notifications === 0}
              >
                📄 JSON
              </button>
              <button
                className="export-btn csv"
                onClick={() => exportNotifications("csv")}
                disabled={loading || stats.notifications === 0}
              >
                📊 CSV
              </button>
            </div>
          </div>

          {/* Export Programs */}
          <div className="export-card">
            <h3>📅 Export programs</h3>
            <p>
              Download all conference sessions and presentations (
              {stats.programs} documents)
            </p>
            <div className="export-buttons">
              <button
                className="export-btn json"
                onClick={() => exportPrograms("json")}
                disabled={loading || stats.programs === 0}
              >
                📄 JSON
              </button>
              <button
                className="export-btn csv"
                onClick={() => exportPrograms("csv")}
                disabled={loading || stats.programs === 0}
              >
                📊 CSV
              </button>
            </div>
          </div>

          {/* Export Ratings */}
          <div className="export-card">
            <h3>⭐ Export ratings</h3>
            <p>
              Download all user ratings and feedback ({stats.ratings} documents)
            </p>
            <div className="export-buttons">
              <button
                className="export-btn json"
                onClick={() => exportRatings("json")}
                disabled={loading || stats.ratings === 0}
              >
                📄 JSON
              </button>
              <button
                className="export-btn csv"
                onClick={() => exportRatings("csv")}
                disabled={loading || stats.ratings === 0}
              >
                📊 CSV
              </button>
            </div>
          </div>

          {/* Export Analytics */}
          <div className="export-card">
            <h3>📊 Export presentation_analytics</h3>
            <p>
              Download aggregated presentation analytics (
              {stats.presentationAnalytics} documents)
            </p>
            <div className="export-buttons">
              <button
                className="export-btn json"
                onClick={() => exportAnalytics("json")}
                disabled={loading || stats.presentationAnalytics === 0}
              >
                📄 JSON
              </button>
              <button
                className="export-btn csv"
                onClick={() => exportAnalytics("csv")}
                disabled={loading || stats.presentationAnalytics === 0}
              >
                📊 CSV
              </button>
            </div>
          </div>

          {/* Export Users */}
          <div className="export-card">
            <h3>👥 Export users</h3>
            <p>
              Download all user accounts and profiles ({stats.users} documents)
            </p>
            <div className="export-buttons">
              <button
                className="export-btn json"
                onClick={() => exportUsers("json")}
                disabled={loading || stats.users === 0}
              >
                📄 JSON
              </button>
              <button
                className="export-btn csv"
                onClick={() => exportUsers("csv")}
                disabled={loading || stats.users === 0}
              >
                📊 CSV
              </button>
            </div>
          </div>

          {/* Export Questions */}
          <div className="export-card">
            <h3>❓ Export questions</h3>
            <p>
              Download all live stream Q&A messages ({stats.questions}{" "}
              documents)
            </p>
            <div className="export-buttons">
              <button
                className="export-btn json"
                onClick={() => exportQuestions("json")}
                disabled={loading || stats.questions === 0}
              >
                📄 JSON
              </button>
              <button
                className="export-btn csv"
                onClick={() => exportQuestions("csv")}
                disabled={loading || stats.questions === 0}
              >
                📊 CSV
              </button>
            </div>
          </div>

          {/* Export Live Notifications */}
          <div className="export-card">
            <h3>🔔 Export live_notifications</h3>
            <p>
              Download real-time notification queue ({stats.liveNotifications}{" "}
              documents)
            </p>
            <div className="export-buttons">
              <button
                className="export-btn json"
                onClick={() => exportLiveNotifications("json")}
                disabled={loading || stats.liveNotifications === 0}
              >
                📄 JSON
              </button>
              <button
                className="export-btn csv"
                onClick={() => exportLiveNotifications("csv")}
                disabled={loading || stats.liveNotifications === 0}
              >
                📊 CSV
              </button>
            </div>
          </div>

          {/* Export Push Notifications */}
          <div className="export-card">
            <h3>📱 Export push_notifications</h3>
            <p>
              Download push notification queue and history (
              {stats.pushNotifications} documents)
            </p>
            <div className="export-buttons">
              <button
                className="export-btn json"
                onClick={() => exportPushNotifications("json")}
                disabled={loading || stats.pushNotifications === 0}
              >
                📄 JSON
              </button>
              <button
                className="export-btn csv"
                onClick={() => exportPushNotifications("csv")}
                disabled={loading || stats.pushNotifications === 0}
              >
                📊 CSV
              </button>
            </div>
          </div>

          {/* Export User Profiles */}
          <div className="export-card">
            <h3>👤 Export user_profiles</h3>
            <p>
              Download all user profile data ({stats.userProfiles} documents)
            </p>
            <div className="export-buttons">
              <button
                className="export-btn json"
                onClick={() => exportUserProfiles("json")}
                disabled={loading || stats.userProfiles === 0}
              >
                📄 JSON
              </button>
              <button
                className="export-btn csv"
                onClick={() => exportUserProfiles("csv")}
                disabled={loading || stats.userProfiles === 0}
              >
                📊 CSV
              </button>
            </div>
          </div>

          {/* Export All Data */}
          <div className="export-card complete">
            <h3>🗂️ Complete Database Backup</h3>
            <p>Download everything in one comprehensive backup</p>
            <div className="export-buttons">
              <button
                className="export-btn json primary"
                onClick={() => exportAllData("json")}
                disabled={loading}
              >
                📦 Complete JSON Backup
              </button>
              <button
                className="export-btn csv primary"
                onClick={() => exportAllData("csv")}
                disabled={loading}
              >
                📦 Complete CSV Backup
              </button>
            </div>
          </div>
        </div>

        <div className="export-info">
          <h4>📋 Export Information</h4>
          <ul>
            <li>
              <strong>JSON Format</strong>: Complete data with all fields, ideal
              for backups and data migration
            </li>
            <li>
              <strong>CSV Format</strong>: Spreadsheet-compatible, ideal for
              analysis and reporting
            </li>
            <li>
              <strong>Automatic Timestamps</strong>: All exports include export
              date and metadata
            </li>
            <li>
              <strong>File Naming</strong>: Files automatically named with date
              (e.g., notifications_2025-09-08.json)
            </li>
          </ul>
        </div>
      </div>

      {/* Database Cleanup */}
      <div className="cleanup-section">
        <h2>🧹 Database Cleanup</h2>
        <p>
          Safely clear database collections for new conference years. User
          accounts and profiles are always preserved. All operations require
          confirmation to prevent accidental data loss.
        </p>

        <div className="collections-table-container">
          <table className="collections-table">
            <thead>
              <tr>
                <th>Collection</th>
                <th>Description</th>
                <th>Count</th>
                <th>Confirmation</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>📢 notifications</td>
                <td>Push notification history</td>
                <td>{stats.notifications}</td>
                <td>
                  <input
                    type="text"
                    placeholder="CLEAR_NOTIFICATIONS"
                    value={confirmNotifications}
                    onChange={(e) => setConfirmNotifications(e.target.value)}
                    className="table-confirm-input"
                  />
                </td>
                <td>
                  <button
                    className="table-action-btn danger"
                    onClick={clearNotifications}
                    disabled={
                      loading || confirmNotifications !== "CLEAR_NOTIFICATIONS"
                    }
                  >
                    Clear
                  </button>
                </td>
              </tr>
              <tr>
                <td>📅 programs</td>
                <td>Conference sessions & presentations</td>
                <td>{stats.programs}</td>
                <td>
                  <input
                    type="text"
                    placeholder="CLEAR_PROGRAMS"
                    value={confirmPrograms}
                    onChange={(e) => setConfirmPrograms(e.target.value)}
                    className="table-confirm-input"
                  />
                </td>
                <td>
                  <button
                    className="table-action-btn danger"
                    onClick={clearPrograms}
                    disabled={loading || confirmPrograms !== "CLEAR_PROGRAMS"}
                  >
                    Clear
                  </button>
                </td>
              </tr>
              <tr>
                <td>⭐ ratings</td>
                <td>User ratings & feedback</td>
                <td>{stats.ratings}</td>
                <td>
                  <input
                    type="text"
                    placeholder="CLEAR_RATINGS"
                    value={confirmRatings}
                    onChange={(e) => setConfirmRatings(e.target.value)}
                    className="table-confirm-input"
                  />
                </td>
                <td>
                  <button
                    className="table-action-btn danger"
                    onClick={clearRatings}
                    disabled={loading || confirmRatings !== "CLEAR_RATINGS"}
                  >
                    Clear
                  </button>
                </td>
              </tr>
              <tr>
                <td>📊 presentation_analytics</td>
                <td>Presentation analytics data</td>
                <td>{stats.presentationAnalytics}</td>
                <td>
                  <input
                    type="text"
                    placeholder="CLEAR_ANALYTICS"
                    value={confirmAnalytics}
                    onChange={(e) => setConfirmAnalytics(e.target.value)}
                    className="table-confirm-input"
                  />
                </td>
                <td>
                  <button
                    className="table-action-btn danger"
                    onClick={clearAnalytics}
                    disabled={loading || confirmAnalytics !== "CLEAR_ANALYTICS"}
                  >
                    Clear
                  </button>
                </td>
              </tr>
              <tr>
                <td>❓ questions</td>
                <td>Live stream Q&A messages</td>
                <td>{stats.questions}</td>
                <td>
                  <input
                    type="text"
                    placeholder="CLEAR_QUESTIONS"
                    value={confirmQuestions}
                    onChange={(e) => setConfirmQuestions(e.target.value)}
                    className="table-confirm-input"
                  />
                </td>
                <td>
                  <button
                    className="table-action-btn danger"
                    onClick={clearQuestions}
                    disabled={loading || confirmQuestions !== "CLEAR_QUESTIONS"}
                  >
                    Clear
                  </button>
                </td>
              </tr>
              <tr>
                <td>🔔 live_notifications</td>
                <td>Real-time notification queue</td>
                <td>{stats.liveNotifications}</td>
                <td>
                  <input
                    type="text"
                    placeholder="CLEAR_LIVE_NOTIFICATIONS"
                    value={confirmLiveNotifications}
                    onChange={(e) =>
                      setConfirmLiveNotifications(e.target.value)
                    }
                    className="table-confirm-input"
                  />
                </td>
                <td>
                  <button
                    className="table-action-btn danger"
                    onClick={clearLiveNotifications}
                    disabled={
                      loading ||
                      confirmLiveNotifications !== "CLEAR_LIVE_NOTIFICATIONS"
                    }
                  >
                    Clear
                  </button>
                </td>
              </tr>
              <tr>
                <td>📱 push_notifications</td>
                <td>Push notification queue & history</td>
                <td>{stats.pushNotifications}</td>
                <td>
                  <input
                    type="text"
                    placeholder="CLEAR_PUSH_NOTIFICATIONS"
                    value={confirmPushNotifications}
                    onChange={(e) =>
                      setConfirmPushNotifications(e.target.value)
                    }
                    className="table-confirm-input"
                  />
                </td>
                <td>
                  <button
                    className="table-action-btn danger"
                    onClick={clearPushNotifications}
                    disabled={
                      loading ||
                      confirmPushNotifications !== "CLEAR_PUSH_NOTIFICATIONS"
                    }
                  >
                    Clear
                  </button>
                </td>
              </tr>
              <tr className="preserved-row">
                <td>👥 users</td>
                <td>User accounts (PRESERVED)</td>
                <td>{stats.users}</td>
                <td colspan="2">
                  <span className="preserved-text">
                    ⚠️ User accounts are protected and preserved
                  </span>
                </td>
              </tr>
              <tr className="preserved-row">
                <td>👤 user_profiles</td>
                <td>User profile data (PRESERVED)</td>
                <td>{stats.userProfiles}</td>
                <td colspan="2">
                  <span className="preserved-text">
                    ⚠️ User profiles are protected and preserved
                  </span>
                </td>
              </tr>
              <tr className="clear-all-row">
                <td>
                  <strong>🗑️ CLEAR ALL</strong>
                </td>
                <td>
                  <strong>Remove ALL conference data at once</strong>
                </td>
                <td>
                  <strong>
                    {stats.notifications +
                      stats.programs +
                      stats.ratings +
                      stats.presentationAnalytics +
                      stats.questions +
                      stats.liveNotifications +
                      stats.pushNotifications}
                  </strong>
                </td>
                <td>
                  <input
                    type="text"
                    placeholder="CLEAR_ALL_DATA"
                    value={confirmAllData}
                    onChange={(e) => setConfirmAllData(e.target.value)}
                    className="table-confirm-input critical"
                  />
                </td>
                <td>
                  <button
                    className="table-action-btn critical"
                    onClick={clearAllData}
                    disabled={loading || confirmAllData !== "CLEAR_ALL_DATA"}
                  >
                    Clear All
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* Status Display */}
      <div className="status-section">
        <h3>Status</h3>
        <div className={`status-display ${loading ? "loading" : ""}`}>
          {loading && <div className="spinner"></div>}
          <span>{status || "Ready to manage database"}</span>
        </div>
      </div>

      {/* Safety Information */}
      <div className="safety-info">
        <h3>🛡️ Safety Information</h3>
        <ul>
          <li>
            <strong>User accounts are preserved</strong> - Users can still log
            in with existing accounts
          </li>
          <li>
            <strong>User profiles are preserved</strong> - User profile data
            remains intact
          </li>
          <li>
            <strong>Authentication data is safe</strong> - Login credentials
            remain intact
          </li>
          <li>
            <strong>System configuration preserved</strong> - App settings and
            structure maintained
          </li>
          <li>
            <strong>Notifications are cleared</strong> - All push notification
            history removed
          </li>
          <li>
            <strong>Programs are cleared</strong> - All sessions, presentations
            removed
          </li>
          <li>
            <strong>Ratings are cleared</strong> - All user ratings and comments
            removed
          </li>
          <li>
            <strong>Analytics are cleared</strong> - All aggregated presentation
            statistics removed
          </li>
          <li>
            <strong>Questions are cleared</strong> - All live stream Q&A
            messages removed
          </li>
          <li>
            <strong>Live notifications are cleared</strong> - All real-time
            notification queue removed
          </li>
          <li>
            <strong>Push notifications are cleared</strong> - All push
            notification queue and history removed
          </li>
          <li>
            <strong>Best practice</strong> - Export data before clearing if
            backup is needed
          </li>
        </ul>
      </div>

      {/* Backup Recommendation */}
      <div className="backup-info">
        <h3>💾 Backup Recommendation</h3>
        <p>
          Before clearing data, consider exporting important information through
          the Analytics pages. User data and system settings will remain safe,
          but conference-specific data will be permanently removed.
        </p>
      </div>
    </div>
  );
};

export default DatabaseManager;

import React, { useState } from "react";
import { collection, getDocs, deleteDoc, doc } from "firebase/firestore";
import { db } from "../firebase";
import "../styles/database.css";

const DatabaseManager = () => {
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");
  const [confirmNotifications, setConfirmNotifications] = useState("");
  const [confirmPrograms, setConfirmPrograms] = useState("");
  const [confirmAllData, setConfirmAllData] = useState("");
  const [stats, setStats] = useState({
    notifications: 0,
    programs: 0,
    users: 0,
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

      // Count users
      const usersRef = collection(db, "users");
      const usersSnapshot = await getDocs(usersRef);

      setStats({
        notifications: notificationsSnapshot.size,
        programs: programsSnapshot.size,
        users: usersSnapshot.size,
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

  // Clear all data (notifications + programs)
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

      // Execute all deletes
      await Promise.all([...notificationDeletes, ...programDeletes]);

      const totalDeleted = notificationsSnapshot.size + programsSnapshot.size;
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

    // Get all unique keys from all objects
    const allKeys = [...new Set(data.flatMap((obj) => Object.keys(obj)))];

    // Create CSV header
    const csvHeader = allKeys.join(",");

    // Create CSV rows
    const csvRows = data.map((obj) => {
      return allKeys
        .map((key) => {
          const value = obj[key];
          // Handle nested objects, arrays, and special characters
          if (typeof value === "object" && value !== null) {
            return `"${JSON.stringify(value).replace(/"/g, '""')}"`;
          }
          if (
            typeof value === "string" &&
            (value.includes(",") || value.includes('"') || value.includes("\n"))
          ) {
            return `"${value.replace(/"/g, '""')}"`;
          }
          return value || "";
        })
        .join(",");
    });

    const csvContent = [csvHeader, ...csvRows].join("\n");
    const blob = new Blob([csvContent], { type: "text/csv" });
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

  // Export users data
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

  // Export all data
  const exportAllData = async (format = "json") => {
    try {
      setLoading(true);
      setStatus("Exporting all data...");

      // Get all collections
      const [notificationsSnapshot, programsSnapshot, usersSnapshot] =
        await Promise.all([
          getDocs(collection(db, "notifications")),
          getDocs(collection(db, "programs")),
          getDocs(collection(db, "users")),
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
        users: usersSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
        exportedAt: new Date().toISOString(),
        exportMetadata: {
          totalNotifications: notificationsSnapshot.size,
          totalPrograms: programsSnapshot.size,
          totalUsers: usersSnapshot.size,
          exportDate: new Date().toISOString(),
        },
      };

      if (format === "csv") {
        // For CSV, export each collection separately
        exportToCSV(allData.notifications, "all_notifications");
        exportToCSV(allData.programs, "all_programs");
        exportToCSV(allData.users, "all_users");
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
        <div className="stats-grid">
          <div className="stat-card">
            <div className="stat-number">{stats.notifications}</div>
            <div className="stat-label">Notifications</div>
          </div>
          <div className="stat-card">
            <div className="stat-number">{stats.programs}</div>
            <div className="stat-label">Programs</div>
          </div>
          <div className="stat-card">
            <div className="stat-number">{stats.users}</div>
            <div className="stat-label">Users</div>
            <div className="stat-note">⚠️ Users are preserved</div>
          </div>
        </div>
        <button
          className="refresh-btn"
          onClick={getCollectionStats}
          disabled={loading}
        >
          🔄 Refresh Statistics
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
            <h3>📢 Export Notifications</h3>
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
            <h3>📅 Export Programs</h3>
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

          {/* Export Users */}
          <div className="export-card">
            <h3>👥 Export Users</h3>
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

      {/* Clear Actions */}
      <div className="actions-section">
        <h2>🧹 Database Cleanup Actions</h2>

        {/* Clear Notifications */}
        <div className="action-card">
          <h3>Clear Notifications</h3>
          <p>
            Remove all notification documents. Safe to clear for new
            conferences.
          </p>
          <div className="action-controls">
            <input
              type="text"
              placeholder="Type 'CLEAR_NOTIFICATIONS' to confirm"
              value={confirmNotifications}
              onChange={(e) => setConfirmNotifications(e.target.value)}
              className="confirm-input"
            />
            <button
              className="action-btn danger"
              onClick={clearNotifications}
              disabled={
                loading || confirmNotifications !== "CLEAR_NOTIFICATIONS"
              }
            >
              Clear Notifications ({stats.notifications} docs)
            </button>
          </div>
        </div>

        {/* Clear Programs */}
        <div className="action-card">
          <h3>Clear Programs</h3>
          <p>
            Remove all program/session documents including presentations and
            ratings.
          </p>
          <div className="action-controls">
            <input
              type="text"
              placeholder="Type 'CLEAR_PROGRAMS' to confirm"
              value={confirmPrograms}
              onChange={(e) => setConfirmPrograms(e.target.value)}
              className="confirm-input"
            />
            <button
              className="action-btn danger"
              onClick={clearPrograms}
              disabled={loading || confirmPrograms !== "CLEAR_PROGRAMS"}
            >
              Clear Programs ({stats.programs} docs)
            </button>
          </div>
        </div>

        {/* Clear All Conference Data */}
        <div className="action-card critical">
          <h3>⚠️ Clear All Conference Data</h3>
          <p>
            Remove ALL notifications and programs. This prepares the database
            for a new conference year.
          </p>
          <div className="action-controls">
            <input
              type="text"
              placeholder="Type 'CLEAR_ALL_DATA' to confirm"
              value={confirmAllData}
              onChange={(e) => setConfirmAllData(e.target.value)}
              className="confirm-input"
            />
            <button
              className="action-btn critical"
              onClick={clearAllData}
              disabled={loading || confirmAllData !== "CLEAR_ALL_DATA"}
            >
              Clear All Conference Data ({stats.notifications + stats.programs}{" "}
              docs)
            </button>
          </div>
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
            <strong>Programs are cleared</strong> - All sessions, presentations,
            and ratings removed
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

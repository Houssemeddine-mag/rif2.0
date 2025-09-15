import React, { useState, useEffect } from "react";
import StatisticsService from "../services/StatisticsService";
import "../styles/users.css";

const Users = () => {
  const [userProfiles, setUserProfiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [notificationLoading, setNotificationLoading] = useState(false);
  const [notificationMessage, setNotificationMessage] = useState("");
  const [stats, setStats] = useState({
    totalUsers: 0,
  });

  useEffect(() => {
    fetchUserData();
  }, []);

  const fetchUserData = async () => {
    try {
      setLoading(true);

      // Fetch combined user data (auth + profiles)
      const [userStats, combinedUsers] = await Promise.all([
        StatisticsService.getTotalUsers(),
        StatisticsService.getAuthUsersWithProfiles(),
      ]);

      setStats({
        ...userStats,
      });
      setUserProfiles(combinedUsers);
    } catch (error) {
      console.error("Error fetching user data:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleNotifyIncompleteUsers = async () => {
    setNotificationLoading(true);
    setNotificationMessage("");

    try {
      const result = await StatisticsService.notifyIncompleteProfileUsers();

      if (result.success) {
        setNotificationMessage(`✅ ${result.message}`);
      } else {
        setNotificationMessage(`❌ ${result.message}`);
      }
    } catch (error) {
      setNotificationMessage(
        `❌ Failed to send notifications: ${error.message}`
      );
    } finally {
      setNotificationLoading(false);

      // Clear message after 5 seconds
      setTimeout(() => {
        setNotificationMessage("");
      }, 5000);
    }
  };

  const incompleteProfilesCount = userProfiles.filter(
    (profile) => !profile.isProfileComplete
  ).length;

  const formatDate = (timestamp) => {
    if (!timestamp) return "N/A";

    let date;
    if (timestamp instanceof Date) {
      // Already a Date object
      date = timestamp;
    } else if (timestamp.seconds) {
      // Firestore Timestamp
      date = new Date(timestamp.seconds * 1000);
    } else if (typeof timestamp === "string") {
      // String timestamp
      date = new Date(timestamp);
    } else {
      return "N/A";
    }

    // Check if date is valid
    if (isNaN(date.getTime())) {
      return "N/A";
    }

    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const filteredProfiles = userProfiles.filter(
    (profile) =>
      profile.displayName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      profile.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      profile.school?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      profile.location?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      profile.schoolLevel?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <div className="users-container">
        <div className="loading">
          <div className="loading-spinner"></div>
          <p>Loading user data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="users-container">
      <div className="users-header">
        <h1>User Accounts</h1>
        <p className="subtitle">View and manage registered users</p>
      </div>

      {/* Quick Stats */}
      <div className="quick-stats">
        <div className="stat-item">
          <span className="stat-number">{stats.totalUsers}</span>
          <span className="stat-label">Total Users</span>
        </div>
        <div className="stat-item incomplete-profiles">
          <span className="stat-number">{incompleteProfilesCount}</span>
          <span className="stat-label">Incomplete Profiles</span>
        </div>
      </div>

      {/* Notification Section */}
      <div className="notification-section">
        <div className="notification-actions">
          <button
            className={`notify-button ${notificationLoading ? "loading" : ""}`}
            onClick={handleNotifyIncompleteUsers}
            disabled={notificationLoading || incompleteProfilesCount === 0}
          >
            {notificationLoading ? (
              <>
                <div className="button-spinner"></div>
                Sending Notifications...
              </>
            ) : (
              <>
                <svg
                  width="20"
                  height="20"
                  fill="none"
                  viewBox="0 0 24 24"
                  className="notification-icon"
                >
                  <path
                    d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
                Notify Incomplete Profiles ({incompleteProfilesCount})
              </>
            )}
          </button>

          {notificationMessage && (
            <div
              className={`notification-message ${
                notificationMessage.includes("✅") ? "success" : "error"
              }`}
            >
              {notificationMessage}
            </div>
          )}
        </div>
      </div>

      {/* Search Bar */}
      <div className="search-section">
        <div className="search-input-container">
          <svg
            width="20"
            height="20"
            fill="none"
            viewBox="0 0 24 24"
            className="search-icon"
          >
            <path
              d="m21 21-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
          <input
            type="text"
            placeholder="Search users..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="search-input"
          />
        </div>
        <button
          className="refresh-button"
          onClick={fetchUserData}
          disabled={loading}
        >
          <svg width="16" height="16" fill="none" viewBox="0 0 24 24">
            <path
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
          Refresh
        </button>
      </div>

      {/* User Profiles Content */}
      <div className="profiles-section">
        <h3>User Profiles ({filteredProfiles.length})</h3>

        {filteredProfiles.length === 0 ? (
          <div className="no-data-message">
            {searchTerm
              ? "No profiles match your search."
              : "No user profiles found."}
          </div>
        ) : (
          <div className="table-container">
            <table className="users-table">
              <thead>
                <tr>
                  <th>Display Name</th>
                  <th>Email</th>
                  <th>School</th>
                  <th>School Level</th>
                  <th>Gender</th>
                  <th>Location</th>
                  <th>Profile Status</th>
                  <th>Created</th>
                </tr>
              </thead>
              <tbody>
                {filteredProfiles.map((profile) => (
                  <tr key={profile.id}>
                    <td className="name-cell">
                      <div className="user-info">
                        {profile.photoURL && (
                          <img
                            src={profile.photoURL}
                            alt="Profile"
                            className="profile-avatar"
                            onError={(e) => (e.target.style.display = "none")}
                          />
                        )}
                        <div className="user-name">
                          {profile.displayName || "No Name"}
                        </div>
                      </div>
                    </td>
                    <td className="email-cell">{profile.email}</td>
                    <td className="school-cell">{profile.school || "N/A"}</td>
                    <td className="level-cell">
                      {profile.schoolLevel || "N/A"}
                    </td>
                    <td className="gender-cell">{profile.gender || "N/A"}</td>
                    <td className="location-cell">
                      {profile.location || "N/A"}
                    </td>
                    <td className="status-cell">
                      <span
                        className={`status-badge ${
                          profile.isProfileComplete ? "complete" : "incomplete"
                        }`}
                      >
                        {profile.isProfileComplete ? "Complete" : "Incomplete"}
                      </span>
                    </td>
                    <td className="date-cell">
                      {formatDate(profile.createdAt)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default Users;

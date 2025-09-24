import React, { useState, useEffect, useCallback } from "react";
import { onSnapshot, collection } from "firebase/firestore";
import { db } from "../firebase.js";
import "../styles/users.css";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from "recharts";

const Users = () => {
  const [userProfiles, setUserProfiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [stats, setStats] = useState({
    totalUsers: 0,
  });
  const [connectionStatus, setConnectionStatus] = useState("connecting");

  // Chart and filter states
  const [chartFilter, setChartFilter] = useState("gender"); // gender, country, university, wilaya
  const [chartData, setChartData] = useState([]);

  // Function to generate chart data based on current filter
  const generateChartData = useCallback(
    (users) => {
      let data = [];

      switch (chartFilter) {
        case "gender": {
          const genderCounts = {};
          users.forEach((user) => {
            const gender = user.gender || "Not Specified";
            genderCounts[gender] = (genderCounts[gender] || 0) + 1;
          });
          data = Object.entries(genderCounts).map(([key, value]) => ({
            name: key,
            count: value,
            percentage: ((value / users.length) * 100).toFixed(1),
          }));
          break;
        }

        case "country": {
          const countryCounts = {};
          users.forEach((user) => {
            const country = user.country || user.location || "";
            if (
              country.toLowerCase().includes("algeria") ||
              country.toLowerCase().includes("algérie")
            ) {
              countryCounts["Algeria"] = (countryCounts["Algeria"] || 0) + 1;
            } else if (country.trim()) {
              // If there's a country specified that's not Algeria, use the country name
              const countryName =
                country.charAt(0).toUpperCase() +
                country.slice(1).toLowerCase();
              countryCounts[countryName] =
                (countryCounts[countryName] || 0) + 1;
            } else {
              // If no country is specified
              countryCounts["Not Specified"] =
                (countryCounts["Not Specified"] || 0) + 1;
            }
          });
          data = Object.entries(countryCounts)
            .sort(([, a], [, b]) => b - a) // Sort by count descending
            .map(([key, value]) => ({
              name: key,
              count: value,
              percentage: ((value / users.length) * 100).toFixed(1),
            }));
          break;
        }

        case "university": {
          const universityCounts = {};
          users.forEach((user) => {
            const university =
              user.university || user.school || "Not Specified";
            universityCounts[university] =
              (universityCounts[university] || 0) + 1;
          });
          // Get top 10 universities
          data = Object.entries(universityCounts)
            .sort(([, a], [, b]) => b - a)
            .slice(0, 10)
            .map(([key, value]) => ({
              name: key.length > 30 ? key.substring(0, 30) + "..." : key,
              fullName: key,
              count: value,
              percentage: ((value / users.length) * 100).toFixed(1),
            }));
          break;
        }

        case "wilaya": {
          const wilayaCounts = {};
          const algerianWilayas = [
            "Adrar",
            "Chlef",
            "Laghouat",
            "Oum El Bouaghi",
            "Batna",
            "Béjaïa",
            "Biskra",
            "Béchar",
            "Blida",
            "Bouira",
            "Tamanrasset",
            "Tébessa",
            "Tlemcen",
            "Tiaret",
            "Tizi Ouzou",
            "Alger",
            "Djelfa",
            "Jijel",
            "Sétif",
            "Saïda",
            "Skikda",
            "Sidi Bel Abbès",
            "Annaba",
            "Guelma",
            "Constantine",
            "Médéa",
            "Mostaganem",
            "M'Sila",
            "Mascara",
            "Ouargla",
            "Oran",
            "El Bayadh",
            "Illizi",
            "Bordj Bou Arréridj",
            "Boumerdès",
            "El Tarf",
            "Tindouf",
            "Tissemsilt",
            "El Oued",
            "Khenchela",
            "Souk Ahras",
            "Tipaza",
            "Mila",
            "Aïn Defla",
            "Naâma",
            "Aïn Témouchent",
            "Ghardaïa",
            "Relizane",
            "El M'Ghair",
            "El Meniaa",
            "Ouled Djellal",
            "Bordj Badji Mokhtar",
            "Béni Abbès",
            "Timimoun",
            "Touggourt",
            "Djanet",
            "In Salah",
            "In Guezzam",
          ];

          users.forEach((user) => {
            const province = user.province || "";
            const country = user.country || user.location || "";

            if (
              country.toLowerCase().includes("algeria") ||
              country.toLowerCase().includes("algérie")
            ) {
              if (province) {
                // Check if it's a known Algerian wilaya
                const matchingWilaya = algerianWilayas.find(
                  (w) =>
                    province.toLowerCase().includes(w.toLowerCase()) ||
                    w.toLowerCase().includes(province.toLowerCase())
                );
                const wilayaName = matchingWilaya || province;
                wilayaCounts[wilayaName] = (wilayaCounts[wilayaName] || 0) + 1;
              } else {
                wilayaCounts["Algeria (Unspecified)"] =
                  (wilayaCounts["Algeria (Unspecified)"] || 0) + 1;
              }
            } else if (country) {
              wilayaCounts["Outside Algeria"] =
                (wilayaCounts["Outside Algeria"] || 0) + 1;
            }
          });

          data = Object.entries(wilayaCounts)
            .sort(([, a], [, b]) => b - a)
            .slice(0, 15) // Show top 15
            .map(([key, value]) => ({
              name: key,
              count: value,
              percentage: ((value / users.length) * 100).toFixed(1),
            }));
          break;
        }

        default:
          data = [];
      }

      setChartData(data);
    },
    [chartFilter]
  );

  // Function to get colors for chart data
  const getChartColors = (data, filterType) => {
    if (filterType === "gender") {
      return data.map((item) => {
        switch (item.name.toLowerCase()) {
          case "male":
          case "homme":
          case "masculin":
            return "#2563eb"; // Blue
          case "female":
          case "femme":
          case "féminin":
            return "#ec4899"; // Pink
          default:
            return "#000000"; // Black for undefined/not specified
        }
      });
    } else if (filterType === "country") {
      // Different shades for different countries
      const colors = [
        "#8884d8",
        "#82ca9d",
        "#ffc658",
        "#ff7300",
        "#8dd1e1",
        "#d084d0",
        "#ffb347",
      ];
      return data.map((_, index) => colors[index % colors.length]);
    } else {
      // Default color palette for other charts
      const colors = [
        "#8884d8",
        "#82ca9d",
        "#ffc658",
        "#ff7300",
        "#8dd1e1",
        "#d084d0",
        "#ffb347",
        "#87ceeb",
        "#dda0dd",
        "#98fb98",
      ];
      return data.map((_, index) => colors[index % colors.length]);
    }
  };

  useEffect(() => {
    console.log("🔥 Setting up Firebase connections...");

    // Set up real-time listeners for both collections
    const usersCollection = collection(db, "users");
    const userProfilesCollection = collection(db, "user_profiles");

    let unsubscribeUsers, unsubscribeProfiles;
    let authUsersData = [];
    let profilesData = [];

    const combineUserData = () => {
      console.log("🔄 Combining user data...");
      console.log(
        `Auth users: ${authUsersData.length}, Profiles: ${profilesData.length}`
      );

      // Create a map of profiles by uid for quick lookup
      const profilesMap = new Map();
      profilesData.forEach((profile) => {
        const uid = profile.uid || profile.id;
        profilesMap.set(uid, profile);
      });

      // Combine auth users with their profiles
      const combinedUsers = authUsersData.map((authUser) => {
        const profile = profilesMap.get(authUser.uid) || {};

        // Handle different name field combinations - prioritize actual names over email
        let displayName = "";
        if (profile.firstName || profile.lastName) {
          // Prefer first name + last name combination
          displayName = `${profile.firstName || ""} ${
            profile.lastName || ""
          }`.trim();
        } else if (profile.name) {
          // Use the name field if available
          displayName = profile.name;
        } else if (profile.displayName && !profile.displayName.includes("@")) {
          // Use displayName only if it doesn't look like an email
          displayName = profile.displayName;
        } else if (
          authUser.displayName &&
          !authUser.displayName.includes("@")
        ) {
          // Use auth displayName only if it doesn't look like an email
          displayName = authUser.displayName;
        } else {
          // If no proper name is available, use "No Name" instead of email
          displayName = "No Name";
        }

        return {
          id: authUser.id,
          uid: authUser.uid,
          email: authUser.email || profile.email || "",
          displayName: displayName,
          photoURL: authUser.photoURL || profile.photoURL || "",
          emailVerified: authUser.emailVerified,
          disabled: authUser.disabled,
          createdAt: authUser.createdAt || profile.createdAt,
          lastLoginAt: authUser.lastLoginAt,
          // Profile information
          firstName: profile.firstName || "",
          lastName: profile.lastName || "",
          name: profile.name || "",
          school: profile.school || "",
          university: profile.university || "",
          schoolLevel: profile.schoolLevel || "",
          location: profile.location || "",
          country: profile.country || "",
          province: profile.province || "",
          gender: profile.gender || "",
          isProfileComplete: profile.isProfileComplete || false,
          hasProfile: profilesMap.has(authUser.uid),
          // Add profile creation/update times
          profileCreatedAt: profile.createdAt,
          profileUpdatedAt: profile.updatedAt,
        };
      });

      // Also include users who have profiles but no auth entry
      profilesData.forEach((profile) => {
        const uid = profile.uid || profile.id;
        const hasAuthUser = authUsersData.some((user) => user.uid === uid);

        if (!hasAuthUser) {
          let displayName = "";
          if (profile.firstName || profile.lastName) {
            // Prefer first name + last name combination
            displayName = `${profile.firstName || ""} ${
              profile.lastName || ""
            }`.trim();
          } else if (profile.name) {
            // Use the name field if available
            displayName = profile.name;
          } else if (
            profile.displayName &&
            !profile.displayName.includes("@")
          ) {
            // Use displayName only if it doesn't look like an email
            displayName = profile.displayName;
          } else {
            // If no proper name is available, use "No Name" instead of email
            displayName = "No Name";
          }

          combinedUsers.push({
            id: profile.id,
            uid: uid,
            email: profile.email || "",
            displayName: displayName,
            photoURL: profile.photoURL || "",
            emailVerified: false,
            disabled: false,
            createdAt: profile.createdAt,
            lastLoginAt: null,
            // Profile information
            firstName: profile.firstName || "",
            lastName: profile.lastName || "",
            name: profile.name || "",
            school: profile.school || "",
            university: profile.university || "",
            schoolLevel: profile.schoolLevel || "",
            location: profile.location || "",
            country: profile.country || "",
            province: profile.province || "",
            gender: profile.gender || "",
            isProfileComplete: profile.isProfileComplete || false,
            hasProfile: true,
            profileCreatedAt: profile.createdAt,
            profileUpdatedAt: profile.updatedAt,
          });
        }
      });

      // Sort by creation date (most recent first)
      combinedUsers.sort((a, b) => {
        const dateA = a.createdAt || a.profileCreatedAt || new Date(0);
        const dateB = b.createdAt || b.profileCreatedAt || new Date(0);

        const timeA = dateA?.seconds
          ? dateA.seconds * 1000
          : new Date(dateA).getTime();
        const timeB = dateB?.seconds
          ? dateB.seconds * 1000
          : new Date(dateB).getTime();

        return timeB - timeA;
      });

      console.log(
        "✅ User data combined:",
        combinedUsers.length,
        "total users"
      );

      setUserProfiles(combinedUsers);
      setStats({
        totalUsers: combinedUsers.length,
        totalAuthUsers: authUsersData.length,
        totalProfiles: profilesData.length,
      });
      setLoading(false);
      setConnectionStatus("connected");

      // Generate chart data
      generateChartData(combinedUsers);
    };

    // Set up auth users listener
    console.log("📡 Setting up auth users listener...");
    unsubscribeUsers = onSnapshot(
      usersCollection,
      (snapshot) => {
        console.log("🔄 Auth users data updated:", snapshot.size, "users");
        authUsersData = snapshot.docs.map((doc) => {
          const data = doc.data();

          // Format dates
          let createdAt = null;
          let lastLoginAt = null;

          if (data.createdAt) {
            createdAt = data.createdAt;
          }

          if (data.lastLoginAt) {
            lastLoginAt = data.lastLoginAt;
          }

          return {
            id: doc.id,
            uid: data.uid || doc.id,
            email: data.email || "",
            displayName: data.displayName || "",
            emailVerified: data.emailVerified || false,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            disabled: data.disabled || false,
            photoURL: data.photoURL || "",
          };
        });

        combineUserData();
      },
      (error) => {
        console.error("❌ Auth users listener error:", error);
        setConnectionStatus("error");
        setLoading(false);
      }
    );

    // Set up user profiles listener
    console.log("📡 Setting up user profiles listener...");
    unsubscribeProfiles = onSnapshot(
      userProfilesCollection,
      (snapshot) => {
        console.log(
          "🔄 User profiles data updated:",
          snapshot.size,
          "profiles"
        );
        profilesData = snapshot.docs.map((doc) => {
          const data = doc.data();

          return {
            id: doc.id,
            uid: data.uid || doc.id,
            email: data.email || "",
            displayName: data.displayName || "",
            firstName: data.firstName || "",
            lastName: data.lastName || "",
            name: data.name || "",
            photoURL: data.photoURL || "",
            school: data.school || "",
            university: data.university || "",
            schoolLevel: data.schoolLevel || "",
            gender: data.gender || "",
            location: data.location || "",
            country: data.country || "",
            province: data.province || "",
            createdAt: data.createdAt,
            updatedAt: data.updatedAt,
            isProfileComplete: data.isProfileComplete || false,
          };
        });

        combineUserData();
      },
      (error) => {
        console.error("❌ User profiles listener error:", error);
        setConnectionStatus("error");
        setLoading(false);
      }
    );

    // Cleanup listeners on unmount
    return () => {
      console.log("🧹 Cleaning up Firebase listeners...");
      if (unsubscribeUsers) unsubscribeUsers();
      if (unsubscribeProfiles) unsubscribeProfiles();
    };
  }, [generateChartData]);

  // Regenerate chart data when filter changes or user profiles update
  useEffect(() => {
    if (userProfiles.length > 0) {
      generateChartData(userProfiles);
    }
  }, [chartFilter, userProfiles, generateChartData]);

  const incompleteProfilesCount = userProfiles.filter(
    (profile) => !profile.isProfileComplete
  ).length;

  const filteredProfiles = userProfiles.filter(
    (profile) =>
      profile.displayName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      profile.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      profile.school?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      profile.university?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      profile.location?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      profile.country?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      profile.province?.toLowerCase().includes(searchTerm.toLowerCase()) ||
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
        <div className="header-info">
          <p className="subtitle">View and manage registered users</p>
          <div className={`connection-status ${connectionStatus}`}>
            {connectionStatus === "connecting" && (
              <>
                <div className="status-dot connecting"></div>
                <span>Connecting to Firebase...</span>
              </>
            )}
            {connectionStatus === "connected" && (
              <>
                <div className="status-dot connected"></div>
                <span>Real-time updates active</span>
              </>
            )}
            {connectionStatus === "error" && (
              <>
                <div className="status-dot error"></div>
                <span>Connection error</span>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="quick-stats">
        <div className="stat-item">
          <span className="stat-number">{stats.totalUsers}</span>
          <span className="stat-label">Total Users</span>
        </div>
        <div className="stat-item">
          <span className="stat-number">{stats.totalProfiles || 0}</span>
          <span className="stat-label">User Profiles</span>
        </div>
        <div className="stat-item incomplete-profiles">
          <span className="stat-number">{incompleteProfilesCount}</span>
          <span className="stat-label">Incomplete Profiles</span>
        </div>
      </div>

      {/* Charts Section */}
      <div className="charts-section">
        <h3>User Statistics & Analytics</h3>

        <div className="charts-container">
          <div className="chart-filters">
            <h4>Filter Statistics By:</h4>
            <div className="filter-buttons">
              <button
                className={`filter-btn ${
                  chartFilter === "gender" ? "active" : ""
                }`}
                onClick={() => setChartFilter("gender")}
              >
                <svg
                  width="16"
                  height="16"
                  fill="currentColor"
                  viewBox="0 0 16 16"
                >
                  <path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zM7 6a1 1 0 1 1 2 0 1 1 0 0 1-2 0zm1.5 2.5a.5.5 0 0 0-1 0v3a.5.5 0 0 0 1 0v-3z" />
                </svg>
                <div>
                  <span className="filter-title">Gender Distribution</span>
                  <span className="filter-desc">View users by gender</span>
                </div>
              </button>

              <button
                className={`filter-btn ${
                  chartFilter === "country" ? "active" : ""
                }`}
                onClick={() => setChartFilter("country")}
              >
                <svg
                  width="16"
                  height="16"
                  fill="currentColor"
                  viewBox="0 0 16 16"
                >
                  <path d="M8 16s6-5.686 6-10A6 6 0 0 0 2 6c0 4.314 6 10 6 10zm0-7a3 3 0 1 1 0-6 3 3 0 0 1 0 6z" />
                </svg>
                <div>
                  <span className="filter-title">Country Comparison</span>
                  <span className="filter-desc">Algeria vs International</span>
                </div>
              </button>

              <button
                className={`filter-btn ${
                  chartFilter === "university" ? "active" : ""
                }`}
                onClick={() => setChartFilter("university")}
              >
                <svg
                  width="16"
                  height="16"
                  fill="currentColor"
                  viewBox="0 0 16 16"
                >
                  <path d="M8.211 2.047a.5.5 0 0 0-.422 0L2.5 4.5v2.9l5.711 2.378a.5.5 0 0 0 .378 0L14 7.4V4.5L8.211 2.047z" />
                  <path d="M13.5 4.968L8 7.25 2.5 4.968v5.532l5.5 2.295 5.5-2.295V4.968z" />
                </svg>
                <div>
                  <span className="filter-title">Top Universities</span>
                  <span className="filter-desc">
                    Most represented universities
                  </span>
                </div>
              </button>

              <button
                className={`filter-btn ${
                  chartFilter === "wilaya" ? "active" : ""
                }`}
                onClick={() => setChartFilter("wilaya")}
              >
                <svg
                  width="16"
                  height="16"
                  fill="currentColor"
                  viewBox="0 0 16 16"
                >
                  <path d="M12.166 8.94c-.524 1.062-1.234 2.12-1.96 3.07A31.493 31.493 0 0 1 8 14.58a31.481 31.481 0 0 1-2.206-2.57c-.726-.95-1.436-2.008-1.96-3.07C3.304 7.867 3 6.862 3 6a5 5 0 0 1 10 0c0 .862-.305 1.867-.834 2.94zM8 16s6-5.686 6-10A6 6 0 0 0 2 6c0 4.314 6 10 6 10z" />
                  <path d="M8 8a2 2 0 1 1 0-4 2 2 0 0 1 0 4zm0 1a3 3 0 1 0 0-6 3 3 0 0 0 0 6z" />
                </svg>
                <div>
                  <span className="filter-title">Algerian Wilayas</span>
                  <span className="filter-desc">Regional distribution</span>
                </div>
              </button>
            </div>

            <div className="filter-info">
              <div className="current-filter">
                <span className="filter-label">Current View:</span>
                <span className="filter-value">
                  {chartFilter === "gender" && "Gender Distribution"}
                  {chartFilter === "country" && "Country Comparison"}
                  {chartFilter === "university" && "University Rankings"}
                  {chartFilter === "wilaya" && "Wilaya Distribution"}
                </span>
              </div>
              <div className="data-count">
                <span className="count-label">Data Points:</span>
                <span className="count-value">{chartData.length}</span>
              </div>
            </div>
          </div>

          <div className="chart-display">
            {chartData.length > 0 ? (
              <div className="chart-wrapper">
                <div className="chart-header">
                  <h5>
                    {chartFilter === "gender" && "User Gender Distribution"}
                    {chartFilter === "country" &&
                      "Algeria vs International Users"}
                    {chartFilter === "university" && "Top 10 Universities"}
                    {chartFilter === "wilaya" && "Top 15 Algerian Wilayas"}
                  </h5>
                  <span className="total-users">
                    Total Users: {stats.totalUsers}
                  </span>
                </div>
                <ResponsiveContainer width="100%" height={400}>
                  {chartFilter === "country" || chartFilter === "gender" ? (
                    <PieChart>
                      <Pie
                        data={chartData}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, percentage }) =>
                          `${name}: ${percentage}%`
                        }
                        outerRadius={120}
                        fill="#8884d8"
                        dataKey="count"
                      >
                        {chartData.map((entry, index) => (
                          <Cell
                            key={`cell-${index}`}
                            fill={getChartColors(chartData, chartFilter)[index]}
                          />
                        ))}
                      </Pie>
                      <Tooltip formatter={(value) => [value, "Users"]} />
                      <Legend />
                    </PieChart>
                  ) : (
                    <BarChart
                      data={chartData}
                      margin={{
                        top: 20,
                        right: 30,
                        left: 20,
                        bottom: 60,
                      }}
                    >
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis
                        dataKey="name"
                        angle={-45}
                        textAnchor="end"
                        height={100}
                        interval={0}
                        fontSize={12}
                      />
                      <YAxis />
                      <Tooltip
                        formatter={(value) => [value, "Users"]}
                        labelFormatter={(label) =>
                          `${
                            chartData.find((d) => d.name === label)?.fullName ||
                            label
                          }`
                        }
                      />
                      <Legend />
                      <Bar dataKey="count">
                        {chartData.map((entry, index) => (
                          <Cell
                            key={`cell-${index}`}
                            fill={getChartColors(chartData, chartFilter)[index]}
                          />
                        ))}
                      </Bar>
                    </BarChart>
                  )}
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="no-chart-data">
                <div className="no-data-icon">📊</div>
                <h5>No Data Available</h5>
                <p>No data to display for the selected filter.</p>
              </div>
            )}
          </div>
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
                  <th>University</th>
                  <th>Education Level</th>
                  <th>Country</th>
                  <th>Province/Wilaya</th>
                  <th>Gender</th>
                  <th>Profile Status</th>
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
                        <div className="user-details">
                          <div className="user-name">
                            {profile.displayName || "No Name"}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="email-cell">{profile.email}</td>
                    <td className="university-cell">
                      {profile.university || profile.school || "N/A"}
                    </td>
                    <td className="level-cell">
                      {profile.schoolLevel || "N/A"}
                    </td>
                    <td className="country-cell">
                      {profile.country || profile.location || "N/A"}
                    </td>
                    <td className="province-cell">
                      {profile.province || "N/A"}
                    </td>
                    <td className="gender-cell">{profile.gender || "N/A"}</td>
                    <td className="status-cell">
                      <span
                        className={`status-badge ${
                          profile.isProfileComplete ? "complete" : "incomplete"
                        }`}
                      >
                        {profile.isProfileComplete ? "Complete" : "Incomplete"}
                      </span>
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

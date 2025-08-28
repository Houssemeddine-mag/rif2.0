import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import "../styles/topbar.css";

const Topbar = () => {
  const [dateTime, setDateTime] = useState(new Date());
  const [adminUser, setAdminUser] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const timer = setInterval(() => setDateTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    // Get logged-in admin user info
    const userInfo = localStorage.getItem("rifAdminUser");
    if (userInfo) {
      setAdminUser(JSON.parse(userInfo));
    }
  }, []);

  const handleLogout = () => {
    // Clear user session and redirect to login
    localStorage.removeItem("rifAdminUser");
    navigate("/login");
  };

  return (
    <header className="topbar">
      <div className="topbar-logos">
        <img
          src="/src/assets/labolire_T.png"
          alt="Labolire Logo"
          className="logo-img logo1"
        />
        <img
          src="/src/assets/rif non bg.png"
          alt="RIF Logo"
          className="logo-img logo2"
        />
      </div>
      <div className="topbar-title">RIF Admin Panel</div>
      <div className="topbar-user-section">
        {adminUser && (
          <div className="admin-info">
            <span className="admin-email">{adminUser.email}</span>
            <button
              className="logout-btn"
              onClick={handleLogout}
              title="Logout"
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                <polyline points="16,17 21,12 16,7" />
                <line x1="21" y1="12" x2="9" y2="12" />
              </svg>
            </button>
          </div>
        )}
      </div>
      <div className="topbar-datetime">
        <span className="topbar-time">
          {dateTime.toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit",
            second: "2-digit",
          })}
        </span>
        <span className="topbar-date">
          {dateTime.toLocaleDateString(undefined, {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric",
          })}
        </span>
      </div>
    </header>
  );
};

export default Topbar;

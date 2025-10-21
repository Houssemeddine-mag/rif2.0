import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import "../styles/login.css";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    // Hardcoded admin credentials
    const adminCredentials = [
      { email: "Admin1@RIF.com", password: "G7ySjd98hM" },
      { email: "Admin2@RIF.com", password: "J9BsyT23oD" },
    ];

    // Check if the entered credentials match any admin account
    const validAdmin = adminCredentials.find(
      (admin) => admin.email === email && admin.password === password
    );

    if (validAdmin) {
      setLoading(false);
      setError("");

      // Store the logged-in admin info in localStorage
      localStorage.setItem(
        "rifAdminUser",
        JSON.stringify({
          email: validAdmin.email,
          loginTime: new Date().toISOString(),
        })
      );
      navigate("/app/program"); // Go directly to program management
      return;
    }

    // If credentials don't match, show error
    setError(
      "Invalid admin credentials. Please check your email and password."
    );
    setLoading(false);
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <img
          src="/assets/rif non bg.png"
          alt="RIF Logo"
          className="login-logo"
        />
        <h1 className="login-title">RIF Admin Panel</h1>
        <p className="login-subtitle">
          Admin access only. Please enter your credentials.
        </p>
        <form className="login-form" onSubmit={handleSubmit}>
          <div className="login-form-group">
            <label>Admin Email</label>
            <input
              type="email"
              placeholder="Enter admin email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="login-form-group">
            <label>Password</label>
            <div className="password-input-wrapper">
              <input
                type={showPassword ? "text" : "password"}
                placeholder="Enter admin password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <button
                type="button"
                className="password-toggle-btn"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? "Hide password" : "Show password"}
              >
                {showPassword ? (
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
                    <line x1="1" y1="1" x2="23" y2="23"></line>
                  </svg>
                ) : (
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                    <circle cx="12" cy="12" r="3"></circle>
                  </svg>
                )}
              </button>
            </div>
          </div>
          {error && <div className="login-error">{error}</div>}
          <div className="login-form-footer">
            <button
              className="login-btn primary"
              type="submit"
              disabled={loading}
            >
              {loading ? "Logging in..." : "Login to Admin Panel"}
            </button>
          </div>
        </form>
        <div
          className="admin-info"
          style={{
            marginTop: "20px",
            padding: "15px",
            backgroundColor: "#f8f9fa",
            borderRadius: "8px",
            fontSize: "12px",
            color: "#666",
          }}
        >
          <strong>For Administrators:</strong>
          <br />
          Use your assigned admin credentials to access the program management
          system.
        </div>
      </div>
    </div>
  );
};

export default Login;

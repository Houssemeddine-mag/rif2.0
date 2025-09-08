import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import "../styles/login.css";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
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
            <input
              type="password"
              placeholder="Enter admin password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
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

import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { login as apiLogin } from "../services/authApi";
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
    // TESTING: allow static login for test user
    if (email === "h@h.com" && password === "1234") {
      setLoading(false);
      setError("");
      navigate("/app/dashboard");
      return;
    }
    try {
      await apiLogin(email, password);
      navigate("/app/dashboard");
    } catch (err) {
      setError(err.message || "Login failed.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <img
          src="/src/assets/rif non bg.png"
          alt="RIF Logo"
          className="login-logo"
        />
        <h1 className="login-title">Login to RIF</h1>
        <p className="login-subtitle">
          Welcome back! Please login to your account.
        </p>
        <form className="login-form" onSubmit={handleSubmit}>
          <div className="login-form-group">
            <label>Email</label>
            <input
              type="email"
              placeholder="Enter your email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="login-form-group">
            <label>Password</label>
            <input
              type="password"
              placeholder="Enter your password"
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
              {loading ? "Logging in..." : "Login"}
            </button>
            <a href="#" className="forgot-password-link">
              Forgot password?
            </a>
          </div>
        </form>
        <div className="login-divider">
          <span>or login with</span>
        </div>
        <div className="login-icons">
          <button className="login-icon-btn google" title="Google">
            <img
              src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/google/google-original.svg"
              alt="Google"
            />
          </button>
        </div>
        <div className="login-footer">
          <span>Don't have an account?</span>
          <a href="/signin">Sign up</a>
        </div>
      </div>
    </div>
  );
};

export default Login;

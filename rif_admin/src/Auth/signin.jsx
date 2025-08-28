import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { signup as apiSignup } from "../services/authApi";
import "../styles/signin.css";

const Signin = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await apiSignup(email, password);
      navigate("/login");
    } catch (err) {
      setError(err.message || "Sign up failed.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="signin-container">
      <div className="signin-card">
        <img
          src="/src/assets/rif non bg.png"
          alt="RIF Logo"
          className="signin-logo"
        />
        <h1 className="signin-title">Sign Up for RIF</h1>
        <p className="signin-subtitle">
          Create your account using your email or Google
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
              placeholder="Create a password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          {error && <div className="login-error">{error}</div>}
          <button
            className="login-btn primary"
            type="submit"
            disabled={loading}
          >
            {loading ? "Signing up..." : "Sign Up"}
          </button>
        </form>
        <div className="login-divider">
          <span>or sign up with</span>
        </div>
        <div className="login-icons">
          <button className="login-icon-btn google" title="Google">
            <img
              src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/google/google-original.svg"
              alt="Google"
            />
          </button>
        </div>
        <div className="signin-footer">
          <span>Already have an account?</span>
          <a href="/login">Login</a>
        </div>
      </div>
    </div>
  );
};

export default Signin;

import React from "react";
import "../styles/topbar.css";

const ErrorPage = () => (
  <div
    style={{
      minHeight: "100vh",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      background: "#f8eafd",
      color: "#c2185b",
      fontFamily: "poppins, sans-serif",
    }}
  >
    <div
      style={{
        fontSize: "5rem",
        fontWeight: 700,
        marginBottom: "0.5em",
      }}
    >
      404
    </div>
    <div
      style={{
        fontSize: "2rem",
        fontWeight: 500,
        marginBottom: "1em",
      }}
    >
      Page Not Found
    </div>
    <div
      style={{
        fontSize: "1.1rem",
        color: "#6a1b9a",
        marginBottom: "2em",
      }}
    >
      Sorry, the page you are looking for does not exist.
      <br />
      Please check the URL or use the navigation menu.
    </div>
    <a
      href="/app/dashboard"
      style={{
        padding: "0.7em 2em",
        background: "#fc86e5",
        color: "#fff",
        borderRadius: "30px",
        textDecoration: "none",
        fontWeight: 600,
        fontSize: "1.1rem",
        boxShadow: "0 2px 8px rgba(252,134,229,0.12)",
      }}
    >
      Go to Dashboard
    </a>
  </div>
);

export default ErrorPage;

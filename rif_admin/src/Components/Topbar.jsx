import React, { useEffect, useState } from "react";
import "../styles/topbar.css";

const Topbar = () => {
  const [dateTime, setDateTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setDateTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

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
      <div className="topbar-title">RIF admin page</div>
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

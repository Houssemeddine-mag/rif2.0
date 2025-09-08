import { NavLink } from "react-router-dom";
import "../styles/sidebar.css";

const Sidebar = () => (
  <nav className="sidebar">
    <div className="sidebar-header">
      <h2>Menu</h2>
    </div>
    <ul className="sidebar-nav">
      <li>
        <NavLink
          to="/app/dashboard"
          className={({ isActive }) => (isActive ? "active" : undefined)}
        >
          Dashboard
        </NavLink>
      </li>
      <li>
        <NavLink
          to="/app/program"
          className={({ isActive }) => (isActive ? "active" : undefined)}
        >
          Program
        </NavLink>
      </li>
      <li>
        <NavLink
          to="/app/presentations"
          className={({ isActive }) => (isActive ? "active" : undefined)}
        >
          Presentations
        </NavLink>
      </li>
      <li>
        <NavLink
          to="/app/users"
          className={({ isActive }) => (isActive ? "active" : undefined)}
        >
          Users
        </NavLink>
      </li>
    </ul>
    <div className="sidebar-logout-wrapper">
      <button
        className="sidebar-logout-btn"
        onClick={() => {
          // Clear any auth state here if needed
          window.location.href = "/login";
        }}
      >
        Log Out
      </button>
    </div>
  </nav>
);

export default Sidebar;

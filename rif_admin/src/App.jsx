import { useEffect } from "react";
import { Outlet, useNavigate } from "react-router-dom";
import Sidebar from "./Components/Sidebar";
import Topbar from "./Components/Topbar";
import ScrollToTop from "./Components/ScrollToTop";
import "./styles/sidebar.css";

const App = () => {
  const navigate = useNavigate();

  useEffect(() => {
    // Check if user is authenticated
    const adminUser = localStorage.getItem("rifAdminUser");
    if (!adminUser) {
      // If not authenticated, redirect to login
      navigate("/login");
    }
  }, [navigate]);

  return (
    <div className="app-container">
      {/* Navigation Sidebar */}
      <Sidebar />
      <div className="content-wrapper">
        {/* Top Navigation Bar */}
        <Topbar />
        <ScrollToTop />
        {/* Main Content Area */}
        <main className="main-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default App;

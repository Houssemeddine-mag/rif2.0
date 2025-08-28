import { Outlet } from "react-router-dom";
import Sidebar from "./components/Sidebar";
import Topbar from "./components/Topbar";
import ScrollToTop from "./components/ScrollToTop";
import "./styles/sidebar.css";

const App = () => {
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

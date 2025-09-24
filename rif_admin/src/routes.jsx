import { createBrowserRouter } from "react-router-dom";
import App from "./App";
import AuthLayout from "./Components/AuthLayout";
import Dashboard from "./Pages/dashboard";
import Program from "./Pages/program";
import Users from "./Pages/Users";
import Presentations from "./Pages/Presentations";
import DatabaseManager from "./Pages/DatabaseManager";
import KeynoteInApp from "./Pages/KeynoteInApp";

import Login from "./Auth/login";
import ErrorPage from "./Pages/ErrorPage";

const router = createBrowserRouter([
  {
    path: "/",
    element: <AuthLayout />, // No sidebar/topbar for auth
    errorElement: <ErrorPage />,
    children: [
      { path: "login", element: <Login /> },
      { index: true, element: <Login /> },
    ],
  },
  {
    path: "/app",
    element: <App />, // App layout with sidebar/topbar
    errorElement: <ErrorPage />,
    children: [
      { path: "dashboard", element: <Dashboard /> },
      { path: "program", element: <Program /> },
      { path: "presentations", element: <Presentations /> },
      { path: "users", element: <Users /> },
      { path: "database", element: <DatabaseManager /> },
      { path: "keynote-in-app", element: <KeynoteInApp /> },
      { index: true, element: <Program /> }, // Default to program page
    ],
  },
]);

export default router;

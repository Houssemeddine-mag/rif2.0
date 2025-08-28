import { createBrowserRouter } from "react-router-dom";
import App from "./App";
import AuthLayout from "./components/AuthLayout";
import Dashboard from "./Pages/dashboard";
import Program from "./Pages/program";
import Login from "./Auth/login";
import Signin from "./Auth/signin";
import ErrorPage from "./Pages/ErrorPage";

const router = createBrowserRouter([
  {
    path: "/",
    element: <AuthLayout />, // No sidebar/topbar for auth
    errorElement: <ErrorPage />,
    children: [
      { path: "login", element: <Login /> },
      { path: "signin", element: <Signin /> },
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
    ],
  },
]);

export default router;

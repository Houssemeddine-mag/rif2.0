import { useState, useEffect } from "react";
import "../styles/dashboard.css";

const Dashboard = () => {
  // State for all dashboard data
  const [stats, setStats] = useState({
    totalAttendees: 0,
    totalPresenters: 0,
    totalSessions: 0,
    totalQuestions: 0,
  });

  const [topPresenters, setTopPresenters] = useState([]);
  const [recentQuestions, setRecentQuestions] = useState([]);
  const [sessionRatings, setSessionRatings] = useState([]);
  const [loading, setLoading] = useState(true);

  // Simulate fetching data from backend
  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        // In a real app, these would be API calls to your Spring Boot backend
        const statsResponse = {
          totalAttendees: 342,
          totalPresenters: 28,
          totalSessions: 45,
          totalQuestions: 187,
        };

        const presentersResponse = [
          {
            id: 1,
            name: "Dr. Amina Belkadi",
            rating: 4.9,
            sessions: 5,
            organization: "University of Constantine",
          },
          {
            id: 2,
            name: "Prof. Sarah Mekki",
            rating: 4.8,
            sessions: 4,
            organization: "ESI Algiers",
          },
          {
            id: 3,
            name: "Dr. Leila Boukhatem",
            rating: 4.7,
            sessions: 3,
            organization: "USTHB",
          },
          {
            id: 4,
            name: "Prof. Nadia Zerrouki",
            rating: 4.6,
            sessions: 3,
            organization: "ENP",
          },
          {
            id: 5,
            name: "Dr. Fatima Zohra Cherif",
            rating: 4.5,
            sessions: 2,
            organization: "University of Oran",
          },
        ];

        const questionsResponse = [
          {
            id: 1,
            session: "AI Ethics in Research",
            question: "How do we ensure diversity in AI training datasets?",
            askedBy: "Karima B.",
            date: "2025-12-08 10:15",
          },
          {
            id: 2,
            session: "Machine Learning Advances",
            question: "What are the current limitations of transformer models?",
            askedBy: "Samira K.",
            date: "2025-12-08 11:30",
          },
          {
            id: 3,
            session: "Women in Tech Leadership",
            question: "What advice do you have for young female researchers?",
            askedBy: "Nadia T.",
            date: "2025-12-09 09:45",
          },
        ];

        const ratingsResponse = [
          {
            id: 1,
            title: "Opening Keynote: Future of AI",
            rating: 4.8,
            attendees: 120,
          },
          {
            id: 2,
            title: "Workshop: Deep Learning Basics",
            rating: 4.5,
            attendees: 45,
          },
          { id: 3, title: "Panel: Women in Tech", rating: 4.7, attendees: 85 },
        ];

        setStats(statsResponse);
        setTopPresenters(presentersResponse);
        setRecentQuestions(questionsResponse);
        setSessionRatings(ratingsResponse);
        setLoading(false);
      } catch (error) {
        console.error("Error fetching dashboard data:", error);
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  if (loading) {
    return <div className="loading">Loading dashboard data...</div>;
  }

  return (
    <div className="dashboard-container">
      <h1>Admin Dashboard</h1>
      <p className="subtitle">Conference statistics and insights</p>

      {/* Summary Cards */}
      <div className="stats-grid">
        <div className="stat-card glass-card gradient-border animate-card">
          <div className="stat-icon attendees">
            {/* User SVG */}
            <svg width="32" height="32" fill="none" viewBox="0 0 24 24">
              <circle cx="12" cy="8" r="4" fill="url(#attendeesGradient)" />
              <rect
                x="4"
                y="16"
                width="16"
                height="6"
                rx="3"
                fill="url(#attendeesGradient)"
              />
              <defs>
                <linearGradient
                  id="attendeesGradient"
                  x1="0"
                  y1="0"
                  x2="24"
                  y2="24"
                  gradientUnits="userSpaceOnUse"
                >
                  <stop stop-color="#4f8cff" />
                  <stop offset="1" stop-color="#a259ff" />
                </linearGradient>
              </defs>
            </svg>
          </div>
          <h3>Total Attendees</h3>
          <p className="stat-value">{stats.totalAttendees}</p>
        </div>
        <div className="stat-card glass-card gradient-border animate-card">
          <div className="stat-icon presenters">
            {/* Presenter SVG */}
            <svg width="32" height="32" fill="none" viewBox="0 0 24 24">
              <rect
                x="6"
                y="4"
                width="12"
                height="12"
                rx="6"
                fill="url(#presentersGradient)"
              />
              <rect
                x="2"
                y="18"
                width="20"
                height="4"
                rx="2"
                fill="url(#presentersGradient)"
              />
              <defs>
                <linearGradient
                  id="presentersGradient"
                  x1="0"
                  y1="0"
                  x2="24"
                  y2="24"
                  gradientUnits="userSpaceOnUse"
                >
                  <stop stop-color="#4f8cff" />
                  <stop offset="1" stop-color="#a259ff" />
                </linearGradient>
              </defs>
            </svg>
          </div>
          <h3>Presenters</h3>
          <p className="stat-value">{stats.totalPresenters}</p>
        </div>
        <div className="stat-card glass-card gradient-border animate-card">
          <div className="stat-icon sessions">
            {/* Sessions SVG */}
            <svg width="32" height="32" fill="none" viewBox="0 0 24 24">
              <rect
                x="3"
                y="6"
                width="18"
                height="12"
                rx="4"
                fill="url(#sessionsGradient)"
              />
              <rect
                x="7"
                y="10"
                width="10"
                height="4"
                rx="2"
                fill="#fff"
                fill-opacity="0.5"
              />
              <defs>
                <linearGradient
                  id="sessionsGradient"
                  x1="0"
                  y1="0"
                  x2="24"
                  y2="24"
                  gradientUnits="userSpaceOnUse"
                >
                  <stop stop-color="#4f8cff" />
                  <stop offset="1" stop-color="#a259ff" />
                </linearGradient>
              </defs>
            </svg>
          </div>
          <h3>Sessions</h3>
          <p className="stat-value">{stats.totalSessions}</p>
        </div>
        <div className="stat-card glass-card gradient-border animate-card">
          <div className="stat-icon questions">
            {/* Questions SVG */}
            <svg width="32" height="32" fill="none" viewBox="0 0 24 24">
              <ellipse
                cx="12"
                cy="12"
                rx="10"
                ry="8"
                fill="url(#questionsGradient)"
              />
              <path
                d="M12 16v.01"
                stroke="#fff"
                strokeWidth="2"
                strokeLinecap="round"
              />
              <path
                d="M12 12c1.5 0 2-1 2-2s-.5-2-2-2-2 1-2 2"
                stroke="#fff"
                strokeWidth="2"
                strokeLinecap="round"
              />
              <defs>
                <linearGradient
                  id="questionsGradient"
                  x1="0"
                  y1="0"
                  x2="24"
                  y2="24"
                  gradientUnits="userSpaceOnUse"
                >
                  <stop stop-color="#4f8cff" />
                  <stop offset="1" stop-color="#a259ff" />
                </linearGradient>
              </defs>
            </svg>
          </div>
          <h3>Questions</h3>
          <p className="stat-value">{stats.totalQuestions}</p>
        </div>
      </div>

      {/* Top Presenters Section */}
      <div className="dashboard-section">
        <h2>Rated Presenters</h2>
        <div className="presenters-table-container">
          <table className="presenters-table">
            <thead>
              <tr>
                <th>Rank</th>
                <th>Name</th>
                <th>Rating</th>
                <th>Sessions</th>
                <th>Organization</th>
              </tr>
            </thead>
            <tbody>
              {topPresenters.map((presenter, index) => (
                <tr key={presenter.id}>
                  <td>{index + 1}</td>
                  <td>{presenter.name}</td>
                  <td>
                    <span className="rating">{presenter.rating}</span>
                    <span className="stars">
                      {"★".repeat(Math.floor(presenter.rating))}
                      {"☆".repeat(5 - Math.floor(presenter.rating))}
                    </span>
                  </td>
                  <td>{presenter.sessions}</td>
                  <td>{presenter.organization}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Session Ratings Section */}
      <div className="dashboard-section">
        <h2>Rated Sessions</h2>
        <div className="ratings-chart">
          {sessionRatings.map((session) => (
            <div key={session.id} className="rating-bar">
              <div className="session-info">
                <span className="session-title">{session.title}</span>
                <span className="session-rating">{session.rating} ★</span>
              </div>
              <div className="bar-container">
                <div
                  className="bar"
                  style={{ width: `${(session.rating / 5) * 100}%` }}
                ></div>
              </div>
              <div className="session-attendees">
                {session.attendees} attendees
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Recent Questions Section */}
      <div className="dashboard-section">
        <h2>Questions from Attendees</h2>
        <div className="questions-list">
          {recentQuestions.map((question) => (
            <div key={question.id} className="question-card">
              <div className="question-header">
                <span className="session">{question.session}</span>
                <span className="date">{question.date}</span>
              </div>
              <p className="question-text">{question.question}</p>
              <div className="question-footer">
                <span className="asked-by">Asked by: {question.askedBy}</span>
                <button className="action-button">View in Context</button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;

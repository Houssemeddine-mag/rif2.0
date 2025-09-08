import { useState, useEffect } from "react";
import StatisticsService from "../services/StatisticsService";
import "../styles/dashboard.css";

const Dashboard = () => {
  // State for all dashboard data
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalPresentations: 0,
    uniquePresenters: 0,
    ratedPresentations: 0,
    avgPresenterRating: 0,
    avgPresentationRating: 0,
    ratingParticipationRate: 0,
  });

  const [topPresenters, setTopPresenters] = useState([]);
  const [topPresentations, setTopPresentations] = useState([]);
  const [recentComments, setRecentComments] = useState([]);
  const [loading, setLoading] = useState(true);

  // Fetch real data from Firebase
  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);

        // Fetch all statistics in parallel
        const [overallStats, presenters, presentations, comments] =
          await Promise.all([
            StatisticsService.getOverallStatistics(),
            StatisticsService.getTopRatedPresenters(10),
            StatisticsService.getTopRatedPresentations(10),
            StatisticsService.getAllComments(),
          ]);

        setStats(overallStats);
        setTopPresenters(presenters);
        setTopPresentations(presentations);
        setRecentComments(comments.slice(0, 10)); // Show latest 10 comments
      } catch (error) {
        console.error("Error fetching dashboard data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  if (loading) {
    return (
      <div className="loading">
        <div className="loading-spinner"></div>
        <p>Loading dashboard data...</p>
      </div>
    );
  }

  return (
    <div className="dashboard-container">
      <h1>RIF 2025 Admin Dashboard</h1>
      <p className="subtitle">Conference statistics and analytics</p>

      {/* Summary Cards */}
      <div className="stats-grid">
        <div className="stat-card glass-card gradient-border animate-card">
          <div className="stat-icon attendees">
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
                  <stop stopColor="#4f8cff" />
                  <stop offset="1" stopColor="#a259ff" />
                </linearGradient>
              </defs>
            </svg>
          </div>
          <h3>Total Users</h3>
          <p className="stat-value">{stats.totalUsers}</p>
          <p className="stat-subtitle">
            {stats.totalAuthUsers} registered, {stats.totalProfileUsers}{" "}
            profiles
          </p>
        </div>

        <div className="stat-card glass-card gradient-border animate-card">
          <div className="stat-icon presenters">
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
                  <stop stopColor="#4f8cff" />
                  <stop offset="1" stopColor="#a259ff" />
                </linearGradient>
              </defs>
            </svg>
          </div>
          <h3>Presenters</h3>
          <p className="stat-value">{stats.uniquePresenters}</p>
          <p className="stat-subtitle">Unique speakers</p>
        </div>

        <div className="stat-card glass-card gradient-border animate-card">
          <div className="stat-icon sessions">
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
                fillOpacity="0.5"
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
                  <stop stopColor="#4f8cff" />
                  <stop offset="1" stopColor="#a259ff" />
                </linearGradient>
              </defs>
            </svg>
          </div>
          <h3>Presentations</h3>
          <p className="stat-value">{stats.totalPresentations}</p>
          <p className="stat-subtitle">
            {stats.ratedPresentations} rated ({stats.ratingParticipationRate}%)
          </p>
        </div>

        <div className="stat-card glass-card gradient-border animate-card">
          <div className="stat-icon questions">
            <svg width="32" height="32" fill="none" viewBox="0 0 24 24">
              <path
                d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-4h2v2h-2zm1.5-8c.83 0 1.5.67 1.5 1.5 0 1.5-2 1-2 3h2c0-1.5 2-1 2-3 0-1.93-1.57-3.5-3.5-3.5S8.5 6.57 8.5 8.5h2C10.5 7.67 11.17 7 12 7z"
                fill="url(#ratingsGradient)"
              />
              <defs>
                <linearGradient
                  id="ratingsGradient"
                  x1="0"
                  y1="0"
                  x2="24"
                  y2="24"
                  gradientUnits="userSpaceOnUse"
                >
                  <stop stopColor="#4f8cff" />
                  <stop offset="1" stopColor="#a259ff" />
                </linearGradient>
              </defs>
            </svg>
          </div>
          <h3>Average Ratings</h3>
          <p className="stat-value">
            {stats.avgPresentationRating > 0
              ? stats.avgPresentationRating
              : "N/A"}
          </p>
          <p className="stat-subtitle">
            Presenter:{" "}
            {stats.avgPresenterRating > 0 ? stats.avgPresenterRating : "N/A"}
          </p>
        </div>
      </div>

      {/* Top Presenters Section */}
      {topPresenters.length > 0 && (
        <div className="dashboard-section">
          <h2>Top Rated Presenters</h2>
          <div className="presenters-table-container">
            <table className="presenters-table">
              <thead>
                <tr>
                  <th>Rank</th>
                  <th>Name</th>
                  <th>Rating</th>
                  <th>Rated Sessions</th>
                  <th>Total Sessions</th>
                  <th>Affiliation</th>
                </tr>
              </thead>
              <tbody>
                {topPresenters.map((presenter, index) => (
                  <tr key={index}>
                    <td>
                      <span className={`rank ${index < 3 ? "top-three" : ""}`}>
                        {index + 1}
                      </span>
                    </td>
                    <td className="presenter-name">{presenter.name}</td>
                    <td>
                      <span className="rating">{presenter.averageRating}</span>
                      <span className="stars">
                        {"★".repeat(Math.floor(presenter.averageRating))}
                        {presenter.averageRating % 1 >= 0.5 ? "☆" : ""}
                        {"☆".repeat(5 - Math.ceil(presenter.averageRating))}
                      </span>
                    </td>
                    <td>{presenter.ratedSessions}</td>
                    <td>{presenter.totalSessions}</td>
                    <td className="affiliation">{presenter.affiliation}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Top Presentations Section */}
      {topPresentations.length > 0 && (
        <div className="dashboard-section">
          <h2>Top Rated Presentations</h2>
          <div className="presentations-grid">
            {topPresentations.slice(0, 6).map((presentation) => (
              <div
                key={presentation.id}
                className="presentation-card glass-card"
              >
                <div className="presentation-header">
                  <h4 className="presentation-title">{presentation.title}</h4>
                  <div className="presentation-rating">
                    <span className="rating-score">
                      {presentation.presentationRating}
                    </span>
                    <span className="rating-stars">
                      {"★".repeat(Math.floor(presentation.presentationRating))}
                      {presentation.presentationRating % 1 >= 0.5 ? "☆" : ""}
                    </span>
                  </div>
                </div>
                <div className="presentation-details">
                  <p className="presenter">By: {presentation.presenter}</p>
                  <p className="affiliation">{presentation.affiliation}</p>
                  <p className="time">
                    {presentation.start} - {presentation.end}
                  </p>
                  {presentation.isKeynote && (
                    <span className="keynote-badge">Keynote</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Recent Comments Section */}
      {recentComments.length > 0 && (
        <div className="dashboard-section">
          <h2>Recent Comments & Feedback</h2>
          <div className="comments-list">
            {recentComments.map((comment) => (
              <div key={comment.id} className="comment-card glass-card">
                <div className="comment-header">
                  <div className="presentation-info">
                    <h4 className="presentation-title">
                      {comment.presentationTitle}
                    </h4>
                    <p className="presenter">by {comment.presenter}</p>
                  </div>
                  <div className="ratings-info">
                    {comment.presentationRating && (
                      <span className="rating-badge presentation">
                        Presentation: {comment.presentationRating}★
                      </span>
                    )}
                    {comment.presenterRating && (
                      <span className="rating-badge presenter">
                        Presenter: {comment.presenterRating}★
                      </span>
                    )}
                  </div>
                </div>
                <p className="comment-text">"{comment.comment}"</p>
                <div className="comment-footer">
                  <span className="program-info">
                    {comment.programTitle} - {comment.programDate}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* No Data Messages */}
      {topPresenters.length === 0 &&
        topPresentations.length === 0 &&
        recentComments.length === 0 && (
          <div className="no-data-section">
            <div className="no-data-card glass-card">
              <h3>No Rating Data Available</h3>
              <p>
                Ratings and comments will appear here once users start rating
                presentations and presenters through the mobile app.
              </p>
            </div>
          </div>
        )}
    </div>
  );
};

export default Dashboard;

import React, { useState, useEffect } from "react";
import StatisticsService from "../services/StatisticsService";
import "../styles/presentations.css";

const Presentations = () => {
  const [presentations, setPresentations] = useState([]);
  const [selectedPresentation, setSelectedPresentation] = useState(null);
  const [presentationComments, setPresentationComments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [commentsLoading, setCommentsLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [sortBy, setSortBy] = useState("rating"); // rating, title, presenter, date

  useEffect(() => {
    loadPresentations();
  }, []);

  const loadPresentations = async () => {
    try {
      setLoading(true);
      const data = await StatisticsService.getAllPresentations();
      setPresentations(data);
    } catch (error) {
      console.error("Error loading presentations:", error);
    } finally {
      setLoading(false);
    }
  };

  const loadPresentationComments = async (presentation) => {
    try {
      setCommentsLoading(true);
      const comments = await StatisticsService.getPresentationComments(
        presentation.id
      );
      setPresentationComments(comments);
    } catch (error) {
      console.error("Error loading comments:", error);
      setPresentationComments([]);
    } finally {
      setCommentsLoading(false);
    }
  };

  const handlePresentationSelect = (presentation) => {
    setSelectedPresentation(presentation);
    loadPresentationComments(presentation);
  };

  const filteredAndSortedPresentations = presentations
    .filter(
      (presentation) =>
        presentation.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        presentation.presenter
          ?.toLowerCase()
          .includes(searchTerm.toLowerCase()) ||
        presentation.affiliation
          ?.toLowerCase()
          .includes(searchTerm.toLowerCase())
    )
    .sort((a, b) => {
      switch (sortBy) {
        case "rating":
          return (b.averageRating || 0) - (a.averageRating || 0);
        case "title":
          return a.title.localeCompare(b.title);
        case "presenter":
          return a.presenter.localeCompare(b.presenter);
        case "date":
          return new Date(b.programDate || 0) - new Date(a.programDate || 0);
        default:
          return 0;
      }
    });

  const formatDate = (dateString) => {
    if (!dateString) return "N/A";
    try {
      return new Date(dateString).toLocaleDateString("en-US", {
        year: "numeric",
        month: "short",
        day: "numeric",
      });
    } catch {
      return "N/A";
    }
  };

  const renderStars = (rating) => {
    if (!rating) return <span className="no-rating">No ratings yet</span>;

    const stars = [];
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 >= 0.5;

    for (let i = 0; i < fullStars; i++) {
      stars.push(
        <span key={i} className="star filled">
          ★
        </span>
      );
    }

    if (hasHalfStar) {
      stars.push(
        <span key="half" className="star half">
          ☆
        </span>
      );
    }

    const emptyStars = 5 - Math.ceil(rating);
    for (let i = 0; i < emptyStars; i++) {
      stars.push(
        <span key={`empty-${i}`} className="star empty">
          ☆
        </span>
      );
    }

    return (
      <div className="star-rating">
        {stars}
        <span className="rating-value">({rating.toFixed(1)})</span>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="presentations-container">
        <div className="loading">
          <div className="loading-spinner"></div>
          <p>Loading presentations...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="presentations-container">
      <div className="presentations-header">
        <h1>Presentations Management</h1>
        <p className="subtitle">
          View and analyze all conference presentations
        </p>
      </div>

      {/* Controls */}
      <div className="controls-section">
        <div className="search-sort-container">
          <div className="search-input-container">
            <svg
              width="20"
              height="20"
              fill="none"
              viewBox="0 0 24 24"
              className="search-icon"
            >
              <path
                d="m21 21-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
            <input
              type="text"
              placeholder="Search presentations..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="search-input"
            />
          </div>

          <div className="sort-container">
            <label htmlFor="sort-select">Sort by:</label>
            <select
              id="sort-select"
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="sort-select"
            >
              <option value="rating">Highest Rated</option>
              <option value="title">Title A-Z</option>
              <option value="presenter">Presenter A-Z</option>
              <option value="date">Latest First</option>
            </select>
          </div>
        </div>

        <div className="stats-summary">
          <span className="stat-item">
            <strong>{presentations.length}</strong> Total Presentations
          </span>
          <span className="stat-item">
            <strong>
              {presentations.filter((p) => p.averageRating > 0).length}
            </strong>{" "}
            Rated
          </span>
          <span className="stat-item">
            <strong>
              {presentations.filter((p) => p.commentCount > 0).length}
            </strong>{" "}
            With Comments
          </span>
        </div>
      </div>

      <div className="presentations-content">
        {/* Presentations List */}
        <div className="presentations-list">
          <h2>All Presentations ({filteredAndSortedPresentations.length})</h2>

          {filteredAndSortedPresentations.length === 0 ? (
            <div className="no-presentations">
              {searchTerm
                ? "No presentations match your search."
                : "No presentations found."}
            </div>
          ) : (
            <div className="presentations-grid">
              {filteredAndSortedPresentations.map((presentation) => (
                <div
                  key={presentation.id}
                  className={`presentation-card ${
                    selectedPresentation?.id === presentation.id
                      ? "selected"
                      : ""
                  }`}
                  onClick={() => handlePresentationSelect(presentation)}
                >
                  <div className="card-header">
                    <h3 className="presentation-title">{presentation.title}</h3>
                    {presentation.isKeynote && (
                      <span className="keynote-badge">Keynote</span>
                    )}
                  </div>

                  <div className="presenter-info">
                    <div className="presenter-name">
                      <svg
                        width="16"
                        height="16"
                        fill="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" />
                      </svg>
                      {presentation.presenter}
                    </div>
                    {presentation.affiliation && (
                      <div className="affiliation">
                        {presentation.affiliation}
                      </div>
                    )}
                  </div>

                  <div className="presentation-meta">
                    <div className="time-info">
                      <svg
                        width="14"
                        height="14"
                        fill="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path d="M12,2A10,10 0 0,0 2,12A10,10 0 0,0 12,22A10,10 0 0,0 22,12A10,10 0 0,0 12,2M16.2,16.2L11,13V7H12.5V12.2L17,14.7L16.2,16.2Z" />
                      </svg>
                      {presentation.start} - {presentation.end}
                    </div>
                    <div className="date-info">
                      <svg
                        width="14"
                        height="14"
                        fill="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path d="M19,3H18V1H16V3H8V1H6V3H5A2,2 0 0,0 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5A2,2 0 0,0 19,3M19,19H5V8H19V19Z" />
                      </svg>
                      {formatDate(presentation.programDate)}
                    </div>
                  </div>

                  <div className="rating-section">
                    <div className="rating-display">
                      <div className="rating-item">
                        <span className="rating-label">Presentation:</span>
                        {renderStars(presentation.presentationRating)}
                      </div>
                      <div className="rating-item">
                        <span className="rating-label">Presenter:</span>
                        {renderStars(presentation.presenterRating)}
                      </div>
                    </div>

                    <div className="stats-footer">
                      <span className="comment-count">
                        💬 {presentation.commentCount || 0} comments
                      </span>
                      <span className="rating-count">
                        ⭐ {presentation.ratingCount || 0} ratings
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Selected Presentation Details */}
        {selectedPresentation && (
          <div className="presentation-details">
            <div className="details-header">
              <h2>Presentation Details</h2>
              <button
                className="close-details"
                onClick={() => setSelectedPresentation(null)}
              >
                ✕
              </button>
            </div>

            <div className="selected-presentation-info">
              <h3>{selectedPresentation.title}</h3>
              <div className="presenter-details">
                <p>
                  <strong>Presenter:</strong> {selectedPresentation.presenter}
                </p>
                {selectedPresentation.affiliation && (
                  <p>
                    <strong>Affiliation:</strong>{" "}
                    {selectedPresentation.affiliation}
                  </p>
                )}
                <p>
                  <strong>Time:</strong> {selectedPresentation.start} -{" "}
                  {selectedPresentation.end}
                </p>
                <p>
                  <strong>Date:</strong>{" "}
                  {formatDate(selectedPresentation.programDate)}
                </p>
                {selectedPresentation.isKeynote && (
                  <span className="keynote-badge large">
                    Keynote Presentation
                  </span>
                )}
              </div>

              {selectedPresentation.resume && (
                <div className="presentation-abstract">
                  <h4>Abstract</h4>
                  <p>{selectedPresentation.resume}</p>
                </div>
              )}

              <div className="detailed-ratings">
                <h4>Ratings Summary</h4>
                <div className="ratings-grid">
                  <div className="rating-detail">
                    <h5>Presentation Rating</h5>
                    {renderStars(selectedPresentation.presentationRating)}
                    <span className="rating-stats">
                      Based on {selectedPresentation.ratingCount || 0} ratings
                    </span>
                  </div>
                  <div className="rating-detail">
                    <h5>Presenter Rating</h5>
                    {renderStars(selectedPresentation.presenterRating)}
                    <span className="rating-stats">
                      Based on {selectedPresentation.ratingCount || 0} ratings
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="comments-section">
              <h4>Comments & Feedback ({presentationComments.length})</h4>

              {commentsLoading ? (
                <div className="comments-loading">
                  <div className="loading-spinner small"></div>
                  <span>Loading comments...</span>
                </div>
              ) : presentationComments.length === 0 ? (
                <div className="no-comments">
                  <p>No comments yet for this presentation.</p>
                </div>
              ) : (
                <div className="comments-list">
                  {presentationComments.map((comment, index) => (
                    <div key={index} className="comment-card">
                      <div className="comment-header">
                        <div className="comment-ratings">
                          {comment.presentationRating && (
                            <span className="comment-rating presentation">
                              Presentation: {comment.presentationRating}⭐
                            </span>
                          )}
                          {comment.presenterRating && (
                            <span className="comment-rating presenter">
                              Presenter: {comment.presenterRating}⭐
                            </span>
                          )}
                        </div>
                        <span className="comment-date">
                          {formatDate(comment.date)}
                        </span>
                      </div>

                      <div className="comment-text">"{comment.comment}"</div>

                      {comment.userId && (
                        <div className="comment-footer">
                          <span className="comment-author">
                            User ID: {comment.userId}
                          </span>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Presentations;

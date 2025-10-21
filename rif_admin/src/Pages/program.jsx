import { useState, useEffect } from "react";
import "../styles/program.css";
import "../styles/program-form-restore.css";
import FirebaseAdminService from "../services/FirebaseAdminService";

const Program = () => {
  const [sessions, setSessions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    type: "session", // session, keynote, break, ceremony
    title: "",
    date: "",
    start: "",
    end: "",
    endDate: "", // Added end date field for sessions
    room: "", // Added room field
    chairs: [],
    chairInput: "",
    keynote: {
      name: "",
      affiliation: "",
      bio: "",
      image: "",
    },
    keynoteDescription: "",
    keynoteHasConference: false,
    keynoteConference: {
      title: "",
      start: "",
      end: "",
    },
    conferences: [],
    conferenceInput: {
      title: "",
      presenter: "",
      affiliation: "",
      start: "",
      end: "",
      resume: "",
    },
  });
  const [editingId, setEditingId] = useState(null);
  const [editingConferenceIdx, setEditingConferenceIdx] = useState(null);

  // Fetch sessions from Firebase
  useEffect(() => {
    const fetchSessions = async () => {
      try {
        setLoading(true);
        console.log("Initializing Firebase Admin Service...");

        // Initialize the service first
        await FirebaseAdminService.initialize();

        console.log("Fetching programs from Firebase...");
        const programs = await FirebaseAdminService.getPrograms();
        console.log("Fetched programs:", programs);
        setSessions(programs);
      } catch (error) {
        console.error("Error fetching sessions:", error);

        // Show specific error message for common issues
        if (
          error.message.includes("Permission denied") ||
          error.message.includes("security rules")
        ) {
          console.warn(
            "Firebase security rules may need to be configured for development access."
          );
        }

        // Fallback to example data if Firebase fails
        console.log(
          "Using fallback example data due to Firebase connection issues"
        );
        const exampleData = [
          {
            id: "example-1",
            title: "Artificial Intelligence and Healthcare",
            date: "2025-12-08",
            chairs: ["Pr Nawres Khlifa", "Pr Faiza Belala"],
            keynote: {
              name: "Pr Nawres Khlifa",
              affiliation: "El Manar University, Tunisia",
              bio: "Expert in AI and healthcare innovation.",
              image: "https://randomuser.me/api/portraits/men/1.jpg",
            },
            conferences: [
              {
                title:
                  "CoMediC: Empowering Collaborative and Participatory Medical Multimodal Data Collection Projects",
                presenter: "Wafia Abada, Abdelkrim Bouraoumol, and Asma Ayari",
                affiliation: "Constantine",
                start: "10:15",
                end: "10:35",
              },
              {
                title:
                  "A Novel Ensemble Learning Approach for Diabetes Prediction in Imbalanced Datasets",
                presenter:
                  "Djalila Boughareb, Said Bouteldja, and Hamid Seridi",
                affiliation: "Guelma",
                start: "10:35",
                end: "10:55",
              },
              {
                title: "Detection of Atherosclerosis using Deep Learning",
                presenter:
                  "Zahia Guessoum, Juliet C Moso, Stephane Cormier and Mohamed Tahar Bennai",
                affiliation: "France",
                start: "10:55",
                end: "11:15",
              },
            ],
          },
        ];
        setSessions(exampleData);
      } finally {
        setLoading(false);
      }
    };
    fetchSessions();
  }, []);

  // General input change handler for session and keynote fields
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    if (name.startsWith("keynote.")) {
      const key = name.split(".")[1];
      setFormData((prev) => ({
        ...prev,
        keynote: {
          ...prev.keynote,
          [key]: value,
        },
      }));
    } else {
      setFormData((prev) => ({
        ...prev,
        [name]: value,
      }));
    }
  };

  const handleAddChair = () => {
    if (formData.chairInput.trim() !== "") {
      setFormData((prev) => ({
        ...prev,
        chairs: [...prev.chairs, prev.chairInput],
        chairInput: "",
      }));
    }
  };

  const handleRemoveChair = (index) => {
    setFormData((prev) => ({
      ...prev,
      chairs: prev.chairs.filter((_, i) => i !== index),
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Basic validation
      if (!formData.title.trim()) {
        alert("Please enter a session title");
        setLoading(false);
        return;
      }

      if (!formData.date) {
        alert("Please select a date");
        setLoading(false);
        return;
      }

      if (!formData.start) {
        alert("Please enter start time");
        setLoading(false);
        return;
      }

      if (!formData.room.trim()) {
        alert("Please specify the room for this session");
        setLoading(false);
        return;
      }

      let conferences = [...formData.conferences];
      // If keynoteHasConference, ensure the keynote's conference is the first in the list
      if (formData.keynoteHasConference) {
        const keynoteConf = {
          title:
            formData.keynoteConference.title ||
            `${formData.keynote.name} (Keynote)`,
          presenter: formData.keynote.name,
          affiliation: formData.keynote.affiliation,
          start: formData.keynoteConference.start,
          end: formData.keynoteConference.end,
          isKeynote: true,
        };
        // Replace or add as first conference
        if (conferences.length > 0 && conferences[0].isKeynote) {
          conferences[0] = keynoteConf;
        } else {
          conferences = [keynoteConf, ...conferences];
        }
      } else {
        // Remove keynote conference if unchecked
        if (conferences.length > 0 && conferences[0].isKeynote) {
          conferences = conferences.slice(1);
        }
      }

      const sessionData = {
        ...formData,
        conferences,
        keynoteDescription: formData.keynoteDescription,
      };

      if (editingId) {
        // Update existing session
        const updatedSession = { ...sessionData, id: editingId };
        await FirebaseAdminService.updateProgram(editingId, sessionData);

        // Update local state
        setSessions((prev) =>
          prev.map((session) =>
            session.id === editingId ? updatedSession : session
          )
        );
        console.log("Program updated successfully");
      } else {
        // Add new session
        const newSession = await FirebaseAdminService.addProgram(sessionData);

        // Update local state
        setSessions((prev) => [...prev, newSession]);
        console.log("Program added successfully");
      }

      // Reset form
      setFormData({
        type: "session",
        title: "",
        date: "",
        start: "",
        end: "",
        endDate: "", // Reset end date field
        room: "", // Reset room field
        chairs: [],
        chairInput: "",
        keynote: { name: "", affiliation: "", bio: "", image: "" },
        keynoteDescription: "",
        keynoteHasConference: false,
        keynoteConference: { title: "", start: "", end: "" },
        conferences: [],
        conferenceInput: {
          title: "",
          presenter: "",
          affiliation: "",
          start: "",
          end: "",
          resume: "",
        },
      });
      setEditingId(null);
    } catch (error) {
      console.error("Error saving program:", error);
      alert("Failed to save program. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (session) => {
    setFormData({
      type: session.type || "session",
      title: session.title || "",
      date: session.date || "",
      start: session.start || "",
      end: session.end || "",
      endDate: session.endDate || "", // Include end date in edit
      room: session.room || "", // Include room in edit
      chairs: session.chairs || [],
      chairInput: "",
      keynote: session.keynote || {
        name: "",
        affiliation: "",
        bio: "",
        image: "",
      },
      keynoteDescription: session.keynoteDescription || "",
      keynoteHasConference:
        session.conferences &&
        session.conferences[0] &&
        session.conferences[0].isKeynote
          ? true
          : false,
      keynoteConference:
        session.conferences &&
        session.conferences[0] &&
        session.conferences[0].isKeynote
          ? {
              title: session.conferences[0].title,
              start: session.conferences[0].start,
              end: session.conferences[0].end,
            }
          : { title: "", start: "", end: "" },
      conferences:
        session.conferences &&
        session.conferences[0] &&
        session.conferences[0].isKeynote
          ? session.conferences.slice(1)
          : session.conferences || [],
      conferenceInput: {
        title: "",
        presenter: "",
        affiliation: "",
        start: "",
        end: "",
        resume: "",
      },
    });
    setEditingId(session.id);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleDelete = async (id) => {
    if (window.confirm("Are you sure you want to delete this session?")) {
      setLoading(true);

      try {
        await FirebaseAdminService.deleteProgram(id);

        // Update local state
        setSessions((prev) => prev.filter((session) => session.id !== id));
        console.log("Program deleted successfully");
      } catch (error) {
        console.error("Error deleting program:", error);
        alert("Failed to delete program. Please try again.");
      } finally {
        setLoading(false);
      }
    }
  };

  const formatDate = (dateString) => {
    const options = {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    };
    return new Date(dateString).toLocaleDateString("fr-FR", options);
  };

  if (loading) {
    return <div className="loading">Loading program data...</div>;
  }

  const testFirebaseConnection = async () => {
    try {
      console.log("Testing Firebase connection...");
      await FirebaseAdminService.testConnection();
      alert("✅ Firebase connection successful!");
    } catch (error) {
      console.error("Firebase connection test failed:", error);
      alert("❌ Firebase connection failed: " + error.message);
    }
  };

  return (
    <div className="program-container">
      <h1>Program Management</h1>
      <p className="subtitle">Manage conference schedule and sessions</p>

      {/* Firebase Connection Test */}
      <div style={{ marginBottom: "20px", textAlign: "center" }}>
        <button
          onClick={testFirebaseConnection}
          style={{
            padding: "8px 16px",
            backgroundColor: "#007bff",
            color: "white",
            border: "none",
            borderRadius: "4px",
            cursor: "pointer",
            fontSize: "14px",
          }}
        >
          Test Firebase Connection
        </button>
      </div>

      {/* Session Form */}
      <div className="form-section">
        <h2>{editingId ? "Edit Session" : "Add New Session"}</h2>
        <form onSubmit={handleSubmit} className="session-form">
          <div className="form-row">
            <div className="form-group">
              <label>Date</label>
              <input
                type="date"
                name="date"
                value={formData.date}
                onChange={handleInputChange}
                required
              />
            </div>
            <div className="form-group">
              <label>End Date (Optional)</label>
              <input
                type="date"
                name="endDate"
                value={formData.endDate}
                onChange={handleInputChange}
                placeholder="Leave empty if same as start date"
              />
              <small
                style={{
                  color: "#888",
                  fontSize: "12px",
                  marginTop: "4px",
                  display: "block",
                }}
              >
                Set an end date if the session spans multiple days
              </small>
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Session Title</label>
              <input
                type="text"
                name="title"
                value={formData.title}
                onChange={handleInputChange}
                required
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Session Start Time</label>
              <input
                type="time"
                name="start"
                value={formData.start}
                onChange={handleInputChange}
                required
              />
            </div>
            <div className="form-group">
              <label>Session End Time</label>
              <input
                type="time"
                name="end"
                value={formData.end}
                onChange={handleInputChange}
                required
              />
            </div>
            <div className="form-group">
              <label>Room</label>
              <input
                type="text"
                name="room"
                value={formData.room}
                onChange={handleInputChange}
                placeholder="e.g., Amphitheater A, Room 101, Conference Hall"
                required
              />
            </div>
          </div>

          <div className="form-group">
            <label>Session Chairs</label>
            <div style={{ display: "flex", gap: 8 }}>
              <input
                type="text"
                name="chairInput"
                value={formData.chairInput}
                onChange={handleInputChange}
                placeholder="Add chair name"
              />
              <button
                type="button"
                onClick={handleAddChair}
                className="submit-button"
              >
                Add
              </button>
            </div>
            <div
              style={{
                marginTop: 8,
                display: "flex",
                flexWrap: "wrap",
                gap: 8,
              }}
            >
              {formData.chairs.map((chair, idx) => (
                <span
                  key={idx}
                  style={{
                    background: "#b71b97",
                    color: "#fff",
                    borderRadius: 8,
                    padding: "2px 10px",
                    display: "flex",
                    alignItems: "center",
                    gap: 4,
                  }}
                >
                  {chair}
                  <button
                    type="button"
                    onClick={() => handleRemoveChair(idx)}
                    style={{
                      background: "none",
                      border: "none",
                      color: "#fff",
                      marginLeft: 4,
                      cursor: "pointer",
                      fontWeight: 700,
                    }}
                  >
                    &times;
                  </button>
                </span>
              ))}
            </div>
          </div>

          <div
            className="form-section"
            style={{ marginTop: 24, background: "#f7f7fa" }}
          >
            <h3>Keynote Speaker (Optional)</h3>
            <div className="form-row">
              <div className="form-group">
                <label>Name</label>
                <input
                  type="text"
                  name="keynote.name"
                  value={formData.keynote.name}
                  onChange={handleInputChange}
                  placeholder="Optional - Enter keynote speaker name"
                />
              </div>
              <div className="form-group">
                <label>Affiliation</label>
                <input
                  type="text"
                  name="keynote.affiliation"
                  value={formData.keynote.affiliation}
                  onChange={handleInputChange}
                  placeholder="Optional - Enter speaker affiliation"
                />
              </div>
            </div>
            <div className="form-group">
              <label>Description</label>
              <textarea
                name="keynoteDescription"
                value={formData.keynoteDescription}
                onChange={handleInputChange}
                rows={3}
                placeholder="Enter keynote description..."
                style={{ resize: "vertical" }}
              />
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Bio</label>
                <input
                  type="text"
                  name="keynote.bio"
                  value={formData.keynote.bio}
                  onChange={handleInputChange}
                  placeholder="Optional - Enter speaker bio"
                />
              </div>
              <div className="form-group presenter-image-upload">
                <label>Picture</label>
                <label className="custom-file-label" htmlFor="keynoteImgInput">
                  Choose Image
                </label>
                <input
                  id="keynoteImgInput"
                  type="file"
                  accept="image/*"
                  onChange={(e) => {
                    const file = e.target.files[0];
                    if (file) {
                      const reader = new FileReader();
                      reader.onloadend = () => {
                        setFormData((prev) => ({
                          ...prev,
                          keynote: { ...prev.keynote, image: reader.result },
                        }));
                      };
                      reader.readAsDataURL(file);
                    }
                  }}
                />
                {formData.keynote.image && (
                  <img
                    src={formData.keynote.image}
                    alt="Preview"
                    className="presenter-image-preview"
                  />
                )}
              </div>
            </div>
            <div className="form-group" style={{ marginTop: 12 }}>
              <label
                style={{ display: "flex", alignItems: "center", gap: "8px" }}
              >
                <input
                  type="checkbox"
                  checked={formData.keynoteHasConference}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      keynoteHasConference: e.target.checked,
                    }))
                  }
                  style={{ width: "16px", height: "16px", flexShrink: 0 }}
                />
                Keynote speaker gives a conference
              </label>
            </div>
            {formData.keynoteHasConference && (
              <div
                className="form-row"
                style={{
                  marginTop: 8,
                  background: "#f3e8ff",
                  borderRadius: 8,
                  padding: 12,
                }}
              >
                <div className="form-group">
                  <label>Conference Title</label>
                  <input
                    type="text"
                    value={formData.keynoteConference.title}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        keynoteConference: {
                          ...prev.keynoteConference,
                          title: e.target.value,
                        },
                      }))
                    }
                  />
                </div>
                <div className="form-group">
                  <label>Start Time</label>
                  <input
                    type="time"
                    value={formData.keynoteConference.start}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        keynoteConference: {
                          ...prev.keynoteConference,
                          start: e.target.value,
                        },
                      }))
                    }
                  />
                </div>
                <div className="form-group">
                  <label>End Time</label>
                  <input
                    type="time"
                    value={formData.keynoteConference.end}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        keynoteConference: {
                          ...prev.keynoteConference,
                          end: e.target.value,
                        },
                      }))
                    }
                  />
                </div>
              </div>
            )}
          </div>

          <div
            className="form-section"
            style={{ marginTop: 24, background: "#f7f7fa" }}
          >
            <h3>Conferences in Session</h3>
            <div className="form-row">
              <div className="form-group">
                <label>Title</label>
                <input
                  type="text"
                  name="conferenceTitle"
                  value={formData.conferenceInput.title}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      conferenceInput: {
                        ...prev.conferenceInput,
                        title: e.target.value,
                      },
                    }))
                  }
                />
              </div>
              <div className="form-group">
                <label>Presenter</label>
                <input
                  type="text"
                  name="conferencePresenter"
                  value={formData.conferenceInput.presenter}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      conferenceInput: {
                        ...prev.conferenceInput,
                        presenter: e.target.value,
                      },
                    }))
                  }
                />
              </div>
              <div className="form-group">
                <label>Affiliation</label>
                <input
                  type="text"
                  name="conferenceAffiliation"
                  value={formData.conferenceInput.affiliation}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      conferenceInput: {
                        ...prev.conferenceInput,
                        affiliation: e.target.value,
                      },
                    }))
                  }
                />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Start Time</label>
                <input
                  type="time"
                  name="conferenceStart"
                  value={formData.conferenceInput.start}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      conferenceInput: {
                        ...prev.conferenceInput,
                        start: e.target.value,
                      },
                    }))
                  }
                />
              </div>
              <div className="form-group">
                <label>End Time</label>
                <input
                  type="time"
                  name="conferenceEnd"
                  value={formData.conferenceInput.end}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      conferenceInput: {
                        ...prev.conferenceInput,
                        end: e.target.value,
                      },
                    }))
                  }
                />
              </div>
              <div className="form-group">
                <label>Resume</label>
                <input
                  type="text"
                  name="conferenceResume"
                  value={formData.conferenceInput.resume || ""}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      conferenceInput: {
                        ...prev.conferenceInput,
                        resume: e.target.value,
                      },
                    }))
                  }
                />
              </div>
              <div className="form-group" style={{ alignItems: "flex-end" }}>
                <button
                  type="button"
                  className="submit-button"
                  style={{ marginTop: 0 }}
                  onClick={() => {
                    const c = formData.conferenceInput;
                    if (
                      c.title &&
                      c.presenter &&
                      c.affiliation &&
                      c.start &&
                      c.end
                    ) {
                      if (editingConferenceIdx !== null) {
                        // Update existing conference
                        setFormData((prev) => {
                          const updated = [...prev.conferences];
                          updated[editingConferenceIdx] = c;
                          return {
                            ...prev,
                            conferences: updated,
                            conferenceInput: {
                              title: "",
                              presenter: "",
                              affiliation: "",
                              start: "",
                              end: "",
                              resume: "",
                            },
                          };
                        });
                        setEditingConferenceIdx(null);
                      } else {
                        // Add new conference
                        setFormData((prev) => ({
                          ...prev,
                          conferences: [...prev.conferences, c],
                          conferenceInput: {
                            title: "",
                            presenter: "",
                            affiliation: "",
                            start: "",
                            end: "",
                            resume: "",
                          },
                        }));
                      }
                    }
                  }}
                >
                  {editingConferenceIdx !== null
                    ? "Update Conference"
                    : "Add Conference"}
                </button>
              </div>
            </div>
            {formData.conferences.length > 0 && (
              <div style={{ marginTop: 12 }}>
                <ul>
                  {formData.conferences.map((conf, idx) => (
                    <li
                      key={idx}
                      style={{
                        marginBottom: 6,
                        display: "flex",
                        alignItems: "center",
                        gap: 8,
                      }}
                    >
                      <span>
                        <b>{conf.title}</b> by {conf.presenter} (
                        {conf.affiliation}) [{conf.start} - {conf.end}]
                      </span>
                      <button
                        type="button"
                        className="edit-button"
                        style={{ fontSize: 13, padding: "2px 8px" }}
                        onClick={() => {
                          setFormData((prev) => ({
                            ...prev,
                            conferenceInput: { ...conf },
                          }));
                          setEditingConferenceIdx(idx);
                        }}
                      >
                        Edit
                      </button>
                      <button
                        type="button"
                        className="delete-button"
                        style={{ fontSize: 13, padding: "2px 8px" }}
                        onClick={() => {
                          setFormData((prev) => ({
                            ...prev,
                            conferences: prev.conferences.filter(
                              (_, i) => i !== idx
                            ),
                          }));
                          // If deleting the one being edited, reset input
                          if (editingConferenceIdx === idx) {
                            setFormData((prev) => ({
                              ...prev,
                              conferenceInput: {
                                title: "",
                                presenter: "",
                                affiliation: "",
                                start: "",
                                end: "",
                                resume: "",
                              },
                            }));
                            setEditingConferenceIdx(null);
                          }
                        }}
                      >
                        Delete
                      </button>
                    </li>
                  ))}
                </ul>
                {editingConferenceIdx !== null && (
                  <div style={{ marginTop: 4, color: "#a259ff", fontSize: 13 }}>
                    Editing conference #{editingConferenceIdx + 1}
                    <button
                      type="button"
                      style={{
                        marginLeft: 12,
                        color: "#fff",
                        background: "#aaa",
                        border: "none",
                        borderRadius: 4,
                        padding: "2px 8px",
                        cursor: "pointer",
                      }}
                      onClick={() => {
                        setFormData((prev) => ({
                          ...prev,
                          conferenceInput: {
                            title: "",
                            presenter: "",
                            affiliation: "",
                            start: "",
                            end: "",
                            resume: "",
                          },
                        }));
                        setEditingConferenceIdx(null);
                      }}
                    >
                      Cancel Edit
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>

          <button
            type="submit"
            className="submit-button"
            style={{ marginTop: 24 }}
          >
            {editingId ? "Update Session" : "Add Session"}
          </button>
          {editingId && (
            <button
              type="button"
              className="cancel-button"
              onClick={() => {
                setFormData({
                  type: "session",
                  title: "",
                  date: "",
                  start: "",
                  end: "",
                  endDate: "", // Reset end date field
                  room: "", // Reset room field
                  chairs: [],
                  chairInput: "",
                  keynote: { name: "", affiliation: "", bio: "", image: "" },
                  keynoteDescription: "",
                  keynoteHasConference: false,
                  keynoteConference: { title: "", start: "", end: "" },
                  conferences: [],
                  conferenceInput: {
                    title: "",
                    presenter: "",
                    affiliation: "",
                    start: "",
                    end: "",
                    resume: "",
                  },
                });
                setEditingId(null);
                setEditingConferenceIdx(null);
              }}
            >
              Cancel
            </button>
          )}
        </form>
      </div>

      {/* Sessions Table */}
      <div className="sessions-section">
        <h2>Conference Program</h2>
        <div className="sessions-table-container">
          {sessions.length === 0 ? (
            <div style={{ padding: 24, textAlign: "center", color: "#888" }}>
              No sessions available.
            </div>
          ) : (
            sessions.map((session) => (
              <div
                key={session.id}
                className="session-block"
                style={{
                  marginBottom: 40,
                  background: "#fff",
                  borderRadius: 16,
                  boxShadow: "0 2px 12px rgba(79,140,255,0.07)",
                  padding: 24,
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    marginBottom: 12,
                  }}
                >
                  <div style={{ flex: 1 }}>
                    <div
                      style={{
                        fontWeight: 700,
                        fontSize: 20,
                        color: "#4f8cff",
                      }}
                    >
                      {session.title}
                    </div>
                    <div style={{ color: "#7f8c8d", fontSize: 15 }}>
                      {formatDate(session.date)}
                      {session.endDate && session.endDate !== session.date && (
                        <span> - {formatDate(session.endDate)}</span>
                      )}
                      {" • "}
                      {session.start}
                      {session.end && ` - ${session.end}`}
                      {" • Room: "}
                      {session.room || "Not specified"}
                    </div>
                    <div
                      style={{ color: "#a259ff", fontSize: 14, marginTop: 4 }}
                    >
                      Chairs:{" "}
                      {session.chairs && session.chairs.length > 0 ? (
                        session.chairs.join(", ")
                      ) : (
                        <span style={{ color: "#aaa" }}>None</span>
                      )}
                    </div>
                  </div>
                  <div>
                    <button
                      className="edit-button"
                      onClick={() => handleEdit(session)}
                      style={{ marginRight: 8 }}
                    >
                      Edit
                    </button>
                    <button
                      className="delete-button"
                      onClick={() => handleDelete(session.id)}
                    >
                      Delete
                    </button>
                  </div>
                </div>
                {/* Keynote Speaker - Only show if keynote exists */}
                {session.keynote &&
                  (session.keynote.name ||
                    session.keynote.affiliation ||
                    session.keynote.bio) && (
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        background: "#f7f7fa",
                        borderRadius: 12,
                        padding: 16,
                        marginBottom: 16,
                      }}
                    >
                      {session.keynote && session.keynote.image && (
                        <img
                          src={session.keynote.image}
                          alt="Keynote"
                          style={{
                            width: 64,
                            height: 64,
                            borderRadius: "50%",
                            objectFit: "cover",
                            marginRight: 18,
                            border: "2px solid #a259ff",
                            background: "#fff",
                          }}
                        />
                      )}
                      <div>
                        {session.keynote?.name && (
                          <div
                            style={{
                              fontWeight: 600,
                              fontSize: 17,
                              color: "#232946",
                            }}
                          >
                            {session.keynote.name}
                          </div>
                        )}
                        {session.keynote?.affiliation && (
                          <div style={{ color: "#4f8cff", fontSize: 15 }}>
                            {session.keynote.affiliation}
                          </div>
                        )}
                        {session.keynote?.bio && (
                          <div style={{ color: "#7f8c8d", fontSize: 14 }}>
                            {session.keynote.bio}
                          </div>
                        )}
                        {session.keynoteDescription && (
                          <div
                            style={{
                              color: "#232946",
                              fontSize: 15,
                              marginBottom: 10,
                            }}
                          >
                            <b>Description:</b> {session.keynoteDescription}
                          </div>
                        )}
                      </div>
                    </div>
                  )}
                {/* Conferences Table */}
                <table className="sessions-table" style={{ marginTop: 10 }}>
                  <thead>
                    <tr>
                      <th style={{ width: 120 }}>Time</th>
                      <th>Title</th>
                      <th>Presenter(s)</th>
                      <th>Affiliation</th>
                      <th>Resume</th>
                    </tr>
                  </thead>
                  <tbody>
                    {session.conferences && session.conferences.length > 0 ? (
                      session.conferences.map((conf, idx) => (
                        <tr
                          key={idx}
                          style={
                            conf.isKeynote
                              ? { background: "#f3e8ff", fontWeight: 600 }
                              : {}
                          }
                        >
                          <td>
                            {conf.start} - {conf.end}
                          </td>
                          <td>{conf.title}</td>
                          <td>{conf.presenter}</td>
                          <td>{conf.affiliation}</td>
                          <td>{conf.resume || "-"}</td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td
                          colSpan={5}
                          style={{ color: "#aaa", textAlign: "center" }}
                        >
                          No conferences in this session.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};

export default Program;

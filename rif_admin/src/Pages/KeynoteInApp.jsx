import React, { useState, useEffect } from "react";
import {
  collection,
  addDoc,
  getDocs,
  doc,
  updateDoc,
  deleteDoc,
  orderBy,
  query,
} from "firebase/firestore";

import { db } from "../firebase.js";
import "../styles/keynote-speakers.css";

const KeynoteInApp = () => {
  const [speakers, setSpeakers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingSpeaker, setEditingSpeaker] = useState(null);
  const [formData, setFormData] = useState({
    name: "",
    title: "",
    institution: "",
    biography: "",
    imageData: "", // Store base64 image data instead of URL
    order: 0,
  });
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState("");
  const [uploadingImage, setUploadingImage] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [sortBy, setSortBy] = useState("order");

  useEffect(() => {
    loadSpeakers();
  }, []);

  const loadSpeakers = async () => {
    try {
      setLoading(true);
      console.log("Loading speakers from Firestore...");

      const q = query(
        collection(db, "keynote_speakers"),
        orderBy("order", "asc")
      );
      const querySnapshot = await getDocs(q);
      const speakersList = [];

      console.log("Query snapshot size:", querySnapshot.size);

      querySnapshot.forEach((doc) => {
        speakersList.push({
          id: doc.id,
          ...doc.data(),
        });
      });

      console.log("Loaded speakers:", speakersList);
      setSpeakers(speakersList);
    } catch (error) {
      console.error("Error loading speakers:", error);
      console.error("Error code:", error.code);
      console.error("Error message:", error.message);
      alert(`Error loading speakers: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      // Check file size (5MB limit)
      if (file.size > 5 * 1024 * 1024) {
        alert("Image size should be less than 5MB");
        return;
      }

      // Check file type - support all common image formats
      const allowedTypes = [
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/gif",
        "image/webp",
        "image/bmp",
        "image/svg+xml",
        "image/tiff",
      ];

      if (!allowedTypes.includes(file.type)) {
        alert(
          "Please select a valid image file (JPEG, PNG, GIF, WebP, BMP, SVG, or TIFF)"
        );
        return;
      }

      console.log("Image file selected:", {
        name: file.name,
        type: file.type,
        size: file.size,
        lastModified: file.lastModified,
      });

      setImageFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
      };
      reader.onerror = (error) => {
        console.error("Error reading file:", error);
        alert("Error reading the image file. Please try again.");
      };
      reader.readAsDataURL(file);
    }
  };

  const uploadImage = async () => {
    if (!imageFile) return null;

    setUploadingImage(true);
    try {
      console.log("Converting image to base64...");
      console.log("Image details:", {
        name: imageFile.name,
        type: imageFile.type,
        size: imageFile.size,
      });

      // Check file size (limit to 1MB for Firestore storage)
      if (imageFile.size > 1024 * 1024) {
        alert("Image too large. Please use an image smaller than 1MB.");
        return null;
      }

      return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => {
          console.log("✅ Image converted to base64 successfully");
          resolve(reader.result); // This is the base64 string
        };
        reader.onerror = (error) => {
          console.error("❌ Error converting image:", error);
          reject(error);
        };
        reader.readAsDataURL(imageFile);
      });
    } catch (error) {
      console.error("❌ Error processing image:", error);
      alert("Error processing image: " + error.message);
      return null;
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.name || !formData.institution) {
      alert("Please fill in at least the name and institution fields.");
      return;
    }

    try {
      setLoading(true);
      console.log("Starting to save speaker...");
      console.log("Form data:", formData);

      let imageData = editingSpeaker?.imageData || "";

      if (imageFile) {
        console.log("Processing image...");
        const base64Image = await uploadImage();
        if (base64Image) {
          imageData = base64Image;
          console.log("✅ Image processed successfully");
        } else {
          // If image processing failed, don't proceed
          setLoading(false);
          return;
        }
      }

      const speakerData = {
        ...formData,
        imageData, // Store base64 image data
        order: parseInt(formData.order) || 0,
        createdAt: editingSpeaker
          ? editingSpeaker.createdAt
          : new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      console.log("Saving speaker data to Firestore...");

      if (editingSpeaker) {
        // Update existing speaker
        console.log("Updating existing speaker with ID:", editingSpeaker.id);
        await updateDoc(
          doc(db, "keynote_speakers", editingSpeaker.id),
          speakerData
        );
        console.log("Speaker updated successfully");
      } else {
        // Add new speaker
        console.log("Adding new speaker to Firestore...");
        const docRef = await addDoc(
          collection(db, "keynote_speakers"),
          speakerData
        );
        console.log("Speaker added successfully with ID:", docRef.id);
      }

      console.log("Reloading speakers...");
      await loadSpeakers();
      resetForm();
      setShowModal(false);
      console.log("Operation completed successfully");
    } catch (error) {
      console.error("Error saving speaker:", error);
      console.error("Error code:", error.code);
      console.error("Error message:", error.message);
      alert(`Error saving speaker: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (speaker) => {
    setEditingSpeaker(speaker);
    setFormData({
      name: speaker.name || "",
      title: speaker.title || "",
      institution: speaker.institution || "",
      biography: speaker.biography || "",
      imageData: speaker.imageData || "", // Update to use imageData
      order: speaker.order || 0,
    });
    setImagePreview(speaker.imageData || ""); // Update to use imageData
    setShowModal(true);
  };

  const handleDelete = async (speaker) => {
    if (!window.confirm(`Are you sure you want to delete ${speaker.name}?`)) {
      return;
    }

    try {
      setLoading(true);

      // Since we're using base64, no need to delete from storage
      console.log("Deleting speaker:", speaker.name);

      // Delete speaker document from Firestore
      await deleteDoc(doc(db, "keynote_speakers", speaker.id));
      await loadSpeakers();
    } catch (error) {
      console.error("Error deleting speaker:", error);
      alert("Error deleting speaker. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setFormData({
      name: "",
      title: "",
      institution: "",
      biography: "",
      order: 0,
    });
    setImageFile(null);
    setImagePreview("");
    setEditingSpeaker(null);
  };

  const filteredSpeakers = speakers.filter(
    (speaker) =>
      speaker.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      speaker.institution?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      speaker.title?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const sortedSpeakers = [...filteredSpeakers].sort((a, b) => {
    switch (sortBy) {
      case "name":
        return (a.name || "").localeCompare(b.name || "");
      case "institution":
        return (a.institution || "").localeCompare(b.institution || "");
      case "order":
      default:
        return (a.order || 0) - (b.order || 0);
    }
  });

  return (
    <div className="keynote-speakers-container">
      <div className="speakers-header">
        <div className="header-content">
          <h1 className="page-title">Keynote in App</h1>
          <p className="page-subtitle">
            Manage keynote speakers for the mobile application
          </p>
        </div>
        <button
          className="btn-primary"
          onClick={() => {
            resetForm();
            setShowModal(true);
          }}
        >
          <i className="icon-plus"></i>
          Add New Speaker
        </button>
      </div>

      <div className="speakers-controls">
        <div className="search-container">
          <input
            type="text"
            placeholder="Search speakers..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="search-input"
          />
        </div>

        <div className="sort-container">
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value)}
            className="sort-select"
          >
            <option value="order">Sort by Order</option>
            <option value="name">Sort by Name</option>
            <option value="institution">Sort by Institution</option>
          </select>
        </div>
      </div>

      {loading ? (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading speakers...</p>
        </div>
      ) : (
        <div className="speakers-grid">
          {sortedSpeakers.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">🎤</div>
              <h3>No keynote speakers found</h3>
              <p>
                {searchTerm
                  ? "No speakers match your search criteria."
                  : "Start by adding your first keynote speaker."}
              </p>
            </div>
          ) : (
            sortedSpeakers.map((speaker) => (
              <div key={speaker.id} className="speaker-card">
                <div className="speaker-image-container">
                  {speaker.imageData ? (
                    <img
                      src={speaker.imageData}
                      alt={speaker.name}
                      className="speaker-image"
                    />
                  ) : (
                    <div className="speaker-placeholder">
                      <i className="icon-user"></i>
                    </div>
                  )}
                  <div className="speaker-order">#{speaker.order || 0}</div>
                </div>

                <div className="speaker-info">
                  <h3 className="speaker-name">{speaker.name}</h3>
                  {speaker.title && (
                    <p className="speaker-title">{speaker.title}</p>
                  )}
                  <p className="speaker-institution">{speaker.institution}</p>

                  {speaker.biography && (
                    <p className="speaker-bio">
                      {speaker.biography.length > 100
                        ? `${speaker.biography.substring(0, 100)}...`
                        : speaker.biography}
                    </p>
                  )}
                </div>

                <div className="speaker-actions">
                  <button
                    className="btn-secondary"
                    onClick={() => handleEdit(speaker)}
                  >
                    <i className="icon-edit"></i>
                    Edit
                  </button>
                  <button
                    className="btn-danger"
                    onClick={() => handleDelete(speaker)}
                  >
                    <i className="icon-delete"></i>
                    Delete
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>{editingSpeaker ? "Edit Speaker" : "Add New Speaker"}</h2>
              <button
                className="modal-close"
                onClick={() => setShowModal(false)}
              >
                ×
              </button>
            </div>

            <form onSubmit={handleSubmit} className="speaker-form">
              <div className="form-grid">
                <div className="form-group">
                  <label htmlFor="name">Speaker Name *</label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    placeholder="Enter speaker's full name"
                    required
                  />
                </div>

                <div className="form-group">
                  <label htmlFor="title">Title/Position</label>
                  <input
                    type="text"
                    id="title"
                    name="title"
                    value={formData.title}
                    onChange={handleInputChange}
                    placeholder="e.g., Professor, CEO, Research Director"
                  />
                </div>

                <div className="form-group">
                  <label htmlFor="institution">
                    Institution/Organization *
                  </label>
                  <input
                    type="text"
                    id="institution"
                    name="institution"
                    value={formData.institution}
                    onChange={handleInputChange}
                    placeholder="University, company, or organization"
                    required
                  />
                </div>

                <div className="form-group">
                  <label htmlFor="order">Display Order</label>
                  <input
                    type="number"
                    id="order"
                    name="order"
                    value={formData.order}
                    onChange={handleInputChange}
                    placeholder="0"
                    min="0"
                  />
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="image">Speaker Photo</label>
                <div className="image-upload-container">
                  <input
                    type="file"
                    id="image"
                    accept="image/jpeg,image/jpg,image/png,image/gif,image/webp,image/bmp,image/svg+xml,image/tiff"
                    onChange={handleImageChange}
                    className="file-input"
                  />
                  <div className="file-input-help">
                    Supported formats: JPEG, PNG, GIF, WebP, BMP, SVG, TIFF (Max
                    5MB)
                  </div>
                  {imagePreview && (
                    <div className="image-preview">
                      <img src={imagePreview} alt="Preview" />
                    </div>
                  )}
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="biography">Biography</label>
                <textarea
                  id="biography"
                  name="biography"
                  value={formData.biography}
                  onChange={handleInputChange}
                  placeholder="Speaker's biography, background, and achievements"
                  rows="4"
                />
              </div>

              <div className="form-actions">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => setShowModal(false)}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  disabled={loading || uploadingImage}
                >
                  {loading || uploadingImage ? (
                    <>
                      <div className="loading-spinner small"></div>
                      {uploadingImage ? "Uploading..." : "Saving..."}
                    </>
                  ) : editingSpeaker ? (
                    "Update Speaker"
                  ) : (
                    "Add Speaker"
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default KeynoteInApp;

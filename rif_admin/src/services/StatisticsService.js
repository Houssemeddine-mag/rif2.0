import {
  collection,
  getDocs,
  addDoc,
  serverTimestamp,
  query,
  where,
} from "firebase/firestore";
import { db } from "../firebase.js";

class StatisticsService {
  static programsCollection = collection(db, "programs");
  static usersCollection = collection(db, "users");
  static userProfilesCollection = collection(db, "user_profiles");
  static ratingsCollection = collection(db, "ratings");
  static presentationAnalyticsCollection = collection(
    db,
    "presentation_analytics"
  );

  // Test Firebase connection
  static async testConnection() {
    try {
      await getDocs(this.programsCollection);
      return true;
    } catch (error) {
      console.error("Firebase connection failed:", error);
      throw error;
    }
  }

  // Get total number of registered users
  static async getTotalUsers() {
    try {
      const usersSnapshot = await getDocs(this.usersCollection);
      const userProfilesSnapshot = await getDocs(this.userProfilesCollection);

      // Count unique users from both collections
      const usersFromAuth = usersSnapshot.size;
      const usersFromProfiles = userProfilesSnapshot.size;

      return {
        totalAuthUsers: usersFromAuth,
        totalProfileUsers: usersFromProfiles,
        totalUsers: Math.max(usersFromAuth, usersFromProfiles), // Take the higher count
      };
    } catch (error) {
      console.error("Error fetching user count:", error);
      return {
        totalAuthUsers: 0,
        totalProfileUsers: 0,
        totalUsers: 0,
      };
    }
  }

  // Get online users count (users active in last 10 minutes)
  static async getOnlineUsers() {
    try {
      const usersSnapshot = await getDocs(this.usersCollection);
      const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000); // 10 minutes ago
      let onlineCount = 0;

      usersSnapshot.docs.forEach((doc) => {
        const data = doc.data();

        // Check if user has recent activity (lastActiveAt or lastLoginAt)
        let lastActive = null;

        if (data.lastActiveAt) {
          if (data.lastActiveAt.seconds) {
            lastActive = new Date(data.lastActiveAt.seconds * 1000);
          } else if (typeof data.lastActiveAt === "string") {
            lastActive = new Date(data.lastActiveAt);
          }
        } else if (data.lastLoginAt) {
          if (data.lastLoginAt.seconds) {
            lastActive = new Date(data.lastLoginAt.seconds * 1000);
          } else if (typeof data.lastLoginAt === "string") {
            lastActive = new Date(data.lastLoginAt);
          }
        }

        // Count as online if active within last 10 minutes
        if (lastActive && lastActive > tenMinutesAgo) {
          onlineCount++;
        }
      });

      return onlineCount;
    } catch (error) {
      console.error("Error fetching online users count:", error);
      return 0;
    }
  }

  // Get user profile data with complete information
  static async getUserProfiles() {
    try {
      const userProfilesSnapshot = await getDocs(this.userProfilesCollection);
      const profiles = [];

      userProfilesSnapshot.docs.forEach((doc) => {
        const data = doc.data();

        // Format birthday if it exists
        let formattedBirthday = null;
        if (data.birthday) {
          if (data.birthday.seconds) {
            // Firestore Timestamp
            formattedBirthday = new Date(data.birthday.seconds * 1000);
          } else if (typeof data.birthday === "string") {
            formattedBirthday = new Date(data.birthday);
          }
        }

        // Format created/updated dates
        let createdAt = null;
        let updatedAt = null;

        if (data.createdAt) {
          if (data.createdAt.seconds) {
            createdAt = new Date(data.createdAt.seconds * 1000);
          } else if (typeof data.createdAt === "string") {
            createdAt = new Date(data.createdAt);
          }
        }

        if (data.updatedAt) {
          if (data.updatedAt.seconds) {
            updatedAt = new Date(data.updatedAt.seconds * 1000);
          } else if (typeof data.updatedAt === "string") {
            updatedAt = new Date(data.updatedAt);
          }
        }

        profiles.push({
          id: doc.id,
          uid: data.uid || doc.id,
          email: data.email || "",
          displayName: data.displayName || "",
          photoURL: data.photoURL || "",
          school: data.school || "",
          schoolLevel: data.schoolLevel || "",
          gender: data.gender || "",
          birthday: formattedBirthday,
          location: data.location || "",
          createdAt: createdAt,
          updatedAt: updatedAt,
          isProfileComplete: data.isProfileComplete || false,
        });
      });

      // Sort by creation date (most recent first)
      return profiles.sort((a, b) => {
        if (!a.createdAt && !b.createdAt) return 0;
        if (!a.createdAt) return 1;
        if (!b.createdAt) return -1;
        return b.createdAt - a.createdAt;
      });
    } catch (error) {
      console.error("Error fetching user profiles:", error);
      return [];
    }
  }

  // Get authenticated users data (limited by Firebase security)
  static async getAuthUsers() {
    try {
      const usersSnapshot = await getDocs(this.usersCollection);
      const authUsers = [];

      usersSnapshot.docs.forEach((doc) => {
        const data = doc.data();

        // Format dates
        let createdAt = null;
        let lastLoginAt = null;

        if (data.createdAt) {
          if (data.createdAt.seconds) {
            createdAt = new Date(data.createdAt.seconds * 1000);
          } else if (typeof data.createdAt === "string") {
            createdAt = new Date(data.createdAt);
          }
        }

        if (data.lastLoginAt) {
          if (data.lastLoginAt.seconds) {
            lastLoginAt = new Date(data.lastLoginAt.seconds * 1000);
          } else if (typeof data.lastLoginAt === "string") {
            lastLoginAt = new Date(data.lastLoginAt);
          }
        }

        authUsers.push({
          id: doc.id,
          uid: data.uid || doc.id,
          email: data.email || "",
          displayName: data.displayName || "",
          emailVerified: data.emailVerified || false,
          createdAt: createdAt,
          lastLoginAt: lastLoginAt,
          disabled: data.disabled || false,
          photoURL: data.photoURL || "",
        });
      });

      // Sort by creation date (most recent first)
      return authUsers.sort((a, b) => {
        if (!a.createdAt && !b.createdAt) return 0;
        if (!a.createdAt) return 1;
        if (!b.createdAt) return -1;
        return b.createdAt - a.createdAt;
      });
    } catch (error) {
      console.error("Error fetching auth users:", error);
      return [];
    }
  }

  // Get authenticated users with their profile information combined
  static async getAuthUsersWithProfiles() {
    try {
      // Get all authenticated users from users collection
      const authUsers = await this.getAuthUsers();

      // Get all user profiles
      const userProfilesSnapshot = await getDocs(this.userProfilesCollection);
      const profilesMap = new Map();

      userProfilesSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        profilesMap.set(data.uid || doc.id, {
          id: doc.id,
          ...data,
        });
      });

      // Combine auth users with their profile information
      const combinedUsers = authUsers.map((authUser) => {
        const profile = profilesMap.get(authUser.uid) || {};

        return {
          id: authUser.id,
          uid: authUser.uid,
          email: authUser.email || profile.email || "",
          displayName:
            authUser.displayName ||
            profile.displayName ||
            (profile.firstName && profile.lastName)
              ? `${profile.firstName} ${profile.lastName}`
              : "",
          photoURL: authUser.photoURL || profile.photoURL || "",
          emailVerified: authUser.emailVerified,
          disabled: authUser.disabled,
          createdAt: authUser.createdAt || profile.createdAt,
          lastLoginAt: authUser.lastLoginAt,
          // Profile information
          firstName: profile.firstName || "",
          lastName: profile.lastName || "",
          school: profile.school || "",
          schoolLevel: profile.schoolLevel || "",
          location: profile.location || "",
          gender: profile.gender || "",
          isProfileComplete: profile.isProfileComplete || false,
          hasProfile: profilesMap.has(authUser.uid),
        };
      });

      return combinedUsers;
    } catch (error) {
      console.error("Error fetching auth users with profiles:", error);
      return [];
    }
  }

  // Get user registration statistics over time
  static async getUserRegistrationStats() {
    try {
      const userProfilesSnapshot = await getDocs(this.userProfilesCollection);
      const registrationData = {};

      userProfilesSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        if (data.createdAt) {
          const date = new Date(data.createdAt.seconds * 1000)
            .toISOString()
            .split("T")[0];
          registrationData[date] = (registrationData[date] || 0) + 1;
        }
      });

      return registrationData;
    } catch (error) {
      console.error("Error fetching registration stats:", error);
      return {};
    }
  }

  // Get all presentations with their ratings and comments from new rating system
  static async getPresentationStatistics() {
    try {
      const presentations = await this.getAllPresentations();

      return presentations.map((presentation) => ({
        id: presentation.id,
        programId: presentation.programId,
        programTitle: presentation.programTitle,
        programDate: presentation.programDate,
        title: presentation.title,
        presenter: presentation.presenter,
        affiliation: presentation.affiliation,
        start: presentation.start,
        end: presentation.end,
        isKeynote: presentation.isKeynote,
        presenterRating: presentation.presenterRating,
        presentationRating: presentation.presentationRating,
        comment: presentation.commentCount > 0 ? "Has comments" : null,
        hasRating: presentation.hasRating,
        hasComment: presentation.hasComment,
      }));
    } catch (error) {
      console.error("Error fetching presentation statistics:", error);
      return [];
    }
  }

  // Get top-rated presenters
  static async getTopRatedPresenters(limitCount = 10) {
    try {
      const presentations = await this.getPresentationStatistics();
      const presenterStats = {};

      // Aggregate ratings by presenter
      presentations.forEach((presentation) => {
        if (presentation.presenterRating) {
          const presenter = presentation.presenter;
          if (!presenterStats[presenter]) {
            presenterStats[presenter] = {
              name: presenter,
              affiliation: presentation.affiliation,
              ratings: [],
              sessions: 0,
              totalSessions: 0,
            };
          }
          presenterStats[presenter].ratings.push(presentation.presenterRating);
          presenterStats[presenter].sessions++;
        }

        // Count total sessions for each presenter
        const presenter = presentation.presenter;
        if (!presenterStats[presenter]) {
          presenterStats[presenter] = {
            name: presenter,
            affiliation: presentation.affiliation,
            ratings: [],
            sessions: 0,
            totalSessions: 0,
          };
        }
        presenterStats[presenter].totalSessions++;
      });

      // Calculate average ratings and sort
      const topPresenters = Object.values(presenterStats)
        .map((presenter) => {
          const averageRating =
            presenter.ratings.length > 0
              ? presenter.ratings.reduce((sum, rating) => sum + rating, 0) /
                presenter.ratings.length
              : 0;

          return {
            ...presenter,
            averageRating: parseFloat(averageRating.toFixed(1)),
            ratedSessions: presenter.ratings.length,
          };
        })
        .filter((presenter) => presenter.averageRating > 0) // Only include presenters with ratings
        .sort((a, b) => b.averageRating - a.averageRating)
        .slice(0, limitCount);

      return topPresenters;
    } catch (error) {
      console.error("Error fetching top presenters:", error);
      return [];
    }
  }

  // Get top-rated presentations
  static async getTopRatedPresentations(limitCount = 10) {
    try {
      const presentations = await this.getPresentationStatistics();

      const ratedPresentations = presentations
        .filter((presentation) => presentation.presentationRating)
        .sort((a, b) => b.presentationRating - a.presentationRating)
        .slice(0, limitCount);

      return ratedPresentations;
    } catch (error) {
      console.error("Error fetching top presentations:", error);
      return [];
    }
  }

  // Get all comments and feedback from new rating system
  static async getAllComments() {
    try {
      // Query without orderBy to avoid requiring composite index
      const ratingsSnapshot = await getDocs(this.ratingsCollection);

      // Get user profiles to map userId to displayName
      const userProfilesSnapshot = await getDocs(this.userProfilesCollection);
      const userProfilesMap = {};
      userProfilesSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        const userId = data.uid || doc.id;
        userProfilesMap[userId] = {
          displayName: data.displayName || data.email || "Anonymous User",
          email: data.email || "",
        };
        // Also map by document ID in case uid field is missing
        userProfilesMap[doc.id] = {
          displayName: data.displayName || data.email || "Anonymous User",
          email: data.email || "",
        };
      });

      const comments = [];
      ratingsSnapshot.docs.forEach((doc) => {
        const data = doc.data();

        // Only include ratings that have comments
        if (data.comment && data.comment.trim() !== "") {
          // Get user information with multiple fallback strategies
          const userId = data.userId || "anonymous";
          let userName = "Anonymous User";

          // Try to find user profile by userId
          if (userProfilesMap[userId]) {
            userName = userProfilesMap[userId].displayName;
          }
          // If not found and we have userEmail, try to find by email
          else if (data.userEmail) {
            const profileByEmail = Object.values(userProfilesMap).find(
              (profile) => profile.email === data.userEmail
            );
            if (profileByEmail) {
              userName = profileByEmail.displayName;
            } else {
              // Use email as display name if no profile found
              userName = data.userEmail.split("@")[0]; // Use part before @ as name
            }
          }

          comments.push({
            id: doc.id,
            presentationTitle: data.conferenceTitle,
            presenter: data.presenter,
            programTitle: "RIF 2025", // Could be derived from date/session
            programDate: data.date,
            comment: data.comment,
            presenterRating: data.presenterRating,
            presentationRating: data.presentationRating,
            userId: userId,
            userEmail: data.userEmail,
            userName: userName,
            ratedAt: data.ratedAt ? data.ratedAt.toDate() : new Date(),
          });
        }
      });

      // Sort comments by date client-side (most recent first)
      return comments.sort((a, b) => b.ratedAt - a.ratedAt);
    } catch (error) {
      console.error("Error fetching comments:", error);
      return [];
    }
  }

  // Get overall statistics summary
  static async getOverallStatistics() {
    try {
      const [presentations, userStats] = await Promise.all([
        this.getPresentationStatistics(),
        this.getTotalUsers(),
      ]);

      const totalPresentations = presentations.length;
      const ratedPresentations = presentations.filter(
        (p) => p.hasRating
      ).length;
      const presentationsWithComments = presentations.filter(
        (p) => p.hasComment
      ).length;
      const uniquePresenters = new Set(presentations.map((p) => p.presenter))
        .size;
      const keynoteCount = presentations.filter((p) => p.isKeynote).length;

      // Calculate average ratings
      const presenterRatings = presentations
        .filter((p) => p.presenterRating)
        .map((p) => p.presenterRating);
      const presentationRatings = presentations
        .filter((p) => p.presentationRating)
        .map((p) => p.presentationRating);

      const avgPresenterRating =
        presenterRatings.length > 0
          ? presenterRatings.reduce((sum, rating) => sum + rating, 0) /
            presenterRatings.length
          : 0;

      const avgPresentationRating =
        presentationRatings.length > 0
          ? presentationRatings.reduce((sum, rating) => sum + rating, 0) /
            presentationRatings.length
          : 0;

      return {
        totalUsers: userStats.totalUsers,
        totalAuthUsers: userStats.totalAuthUsers,
        totalProfileUsers: userStats.totalProfileUsers,
        totalPresentations,
        ratedPresentations,
        presentationsWithComments,
        uniquePresenters,
        keynoteCount,
        avgPresenterRating: parseFloat(avgPresenterRating.toFixed(1)),
        avgPresentationRating: parseFloat(avgPresentationRating.toFixed(1)),
        ratingParticipationRate:
          totalPresentations > 0
            ? parseFloat(
                ((ratedPresentations / totalPresentations) * 100).toFixed(1)
              )
            : 0,
      };
    } catch (error) {
      console.error("Error fetching overall statistics:", error);
      return {
        totalUsers: 0,
        totalAuthUsers: 0,
        totalProfileUsers: 0,
        totalPresentations: 0,
        ratedPresentations: 0,
        presentationsWithComments: 0,
        uniquePresenters: 0,
        keynoteCount: 0,
        avgPresenterRating: 0,
        avgPresentationRating: 0,
        ratingParticipationRate: 0,
      };
    }
  }

  // Notify users with incomplete profiles
  static async notifyIncompleteProfileUsers() {
    try {
      const notificationsCollection = collection(db, "notifications");

      // Get users with incomplete profiles
      const userProfilesSnapshot = await getDocs(this.userProfilesCollection);
      const incompleteUsers = [];

      userProfilesSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        if (!data.isProfileComplete) {
          incompleteUsers.push({
            uid: data.uid || doc.id,
            email: data.email,
            displayName: data.displayName,
          });
        }
      });

      if (incompleteUsers.length === 0) {
        return {
          success: true,
          message: "No users with incomplete profiles found.",
          notificationsSent: 0,
        };
      }

      // Create notifications for each incomplete user
      const notificationPromises = incompleteUsers.map((user) =>
        addDoc(notificationsCollection, {
          userId: user.uid,
          title: "Complete Your Profile",
          message:
            "Hi " +
            (user.displayName || "there") +
            "! Please complete your profile to enjoy all features of the RIF 2025 conference app. Update your school, location, and other details to get personalized recommendations.",
          type: "profile_completion",
          isRead: false,
          createdAt: serverTimestamp(),
          priority: "normal",
        })
      );

      await Promise.all(notificationPromises);

      return {
        success: true,
        message: `Successfully sent notifications to ${incompleteUsers.length} users with incomplete profiles.`,
        notificationsSent: incompleteUsers.length,
        users: incompleteUsers,
      };
    } catch (error) {
      console.error(
        "Error sending notifications to incomplete profile users:",
        error
      );
      return {
        success: false,
        message: "Failed to send notifications. Please try again.",
        notificationsSent: 0,
        error: error.message,
      };
    }
  }

  // Get all presentations with detailed information from new rating system
  static async getAllPresentations() {
    try {
      // First, get all programs
      const programsSnapshot = await getDocs(this.programsCollection);

      if (programsSnapshot.docs.length === 0) {
        console.warn("No programs found in the database");
        return [];
      }

      // Get analytics data (this might be empty initially)
      let analyticsMap = {};
      try {
        const presentationAnalyticsSnapshot = await getDocs(
          this.presentationAnalyticsCollection
        );

        presentationAnalyticsSnapshot.docs.forEach((doc) => {
          const data = doc.data();
          analyticsMap[data.presentationId] = data;
        });
      } catch (analyticsError) {
        console.warn("Could not fetch analytics:", analyticsError);
        // Continue without analytics
      }

      // Get all ratings to calculate stats manually
      let ratingsMap = {};
      try {
        const ratingsSnapshot = await getDocs(this.ratingsCollection);

        ratingsSnapshot.docs.forEach((doc) => {
          const data = doc.data();
          const presentationId = data.presentationId;

          if (!ratingsMap[presentationId]) {
            ratingsMap[presentationId] = {
              ratings: [],
              comments: [],
            };
          }

          ratingsMap[presentationId].ratings.push({
            presenterRating: data.presenterRating,
            presentationRating: data.presentationRating,
          });

          if (data.comment && data.comment.trim()) {
            ratingsMap[presentationId].comments.push(data.comment);
          }
        });
      } catch (ratingsError) {
        console.warn("Could not fetch ratings:", ratingsError);
        // Continue without ratings
      }

      const presentations = [];

      programsSnapshot.docs.forEach((doc) => {
        const program = doc.data();

        if (program.conferences && Array.isArray(program.conferences)) {
          program.conferences.forEach((conference) => {
            // Generate the same presentation ID format used in Flutter app
            const presentationId = this._generatePresentationId(
              conference,
              program.date
            );

            // Get analytics data (priority 1: from analytics collection)
            const analytics = analyticsMap[presentationId] || {};

            // Get rating data (priority 2: calculate from individual ratings)
            const ratingData = ratingsMap[presentationId] || {
              ratings: [],
              comments: [],
            };

            // Calculate ratings manually if analytics don't exist
            let presenterRating = analytics.averagePresenterRating || null;
            let presentationRating =
              analytics.averagePresentationRating || null;
            let commentCount = analytics.totalComments || 0;
            let ratingCount = analytics.totalRatings || 0;

            if (!presenterRating && ratingData.ratings.length > 0) {
              const presenterRatings = ratingData.ratings
                .map((r) => r.presenterRating)
                .filter((r) => r > 0);
              if (presenterRatings.length > 0) {
                presenterRating =
                  presenterRatings.reduce((a, b) => a + b, 0) /
                  presenterRatings.length;
              }
            }

            if (!presentationRating && ratingData.ratings.length > 0) {
              const presentationRatings = ratingData.ratings
                .map((r) => r.presentationRating)
                .filter((r) => r > 0);
              if (presentationRatings.length > 0) {
                presentationRating =
                  presentationRatings.reduce((a, b) => a + b, 0) /
                  presentationRatings.length;
              }
            }

            if (!commentCount) {
              commentCount = ratingData.comments.length;
            }

            if (!ratingCount) {
              ratingCount = ratingData.ratings.length;
            }

            const averageRating =
              presenterRating && presentationRating
                ? (presenterRating + presentationRating) / 2
                : presenterRating || presentationRating || null;

            presentations.push({
              id: presentationId,
              programId: doc.id,
              programTitle: program.title,
              programDate: program.date,
              programStart: program.start,
              programEnd: program.end,
              title: conference.title,
              presenter: conference.presenter,
              affiliation: conference.affiliation,
              start: conference.start,
              end: conference.end,
              resume: conference.resume,
              isKeynote: conference.isKeynote || false,
              presenterRating: presenterRating,
              presentationRating: presentationRating,
              averageRating: averageRating,
              commentCount: commentCount,
              ratingCount: ratingCount,
              hasRating: !!(presenterRating || presentationRating),
              hasComment: commentCount > 0,
              // Additional analytics data
              presenterRatingDistribution:
                analytics.presenterRatingDistribution || {},
              presentationRatingDistribution:
                analytics.presentationRatingDistribution || {},
              lastUpdated: analytics.lastUpdated,
            });
          });
        }
      });

      // Sort by average rating (highest first), then by title
      return presentations.sort((a, b) => {
        if (b.averageRating !== a.averageRating) {
          return (b.averageRating || 0) - (a.averageRating || 0);
        }
        return a.title.localeCompare(b.title);
      });
    } catch (error) {
      console.error("Error fetching all presentations:", error);
      return [];
    }
  }

  // Get comments for a specific presentation from new rating system
  static async getPresentationComments(presentationId) {
    try {
      // First try to get from ratings collection
      let ratingsSnapshot;
      try {
        ratingsSnapshot = await getDocs(
          query(
            this.ratingsCollection,
            where("presentationId", "==", presentationId)
          )
        );
      } catch (queryError) {
        console.warn("Query failed, trying to get all ratings:", queryError);
        // Fallback: get all ratings and filter client-side
        ratingsSnapshot = await getDocs(this.ratingsCollection);
      }

      // Get user profiles to map userId to displayName
      const userProfilesSnapshot = await getDocs(this.userProfilesCollection);
      const userProfilesMap = {};
      userProfilesSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        const userId = data.uid || doc.id;
        userProfilesMap[userId] = {
          displayName: data.displayName || data.email || "Anonymous User",
          email: data.email || "",
        };
        // Also map by document ID in case uid field is missing
        userProfilesMap[doc.id] = {
          displayName: data.displayName || data.email || "Anonymous User",
          email: data.email || "",
        };
      });

      const comments = [];
      ratingsSnapshot.docs.forEach((doc) => {
        const data = doc.data();

        // If we got all ratings, filter by presentationId
        if (
          ratingsSnapshot.docs.length > 50 &&
          data.presentationId !== presentationId
        ) {
          return; // Skip if not matching (when we got all docs)
        }

        // Only include ratings that have comments
        if (data.comment && data.comment.trim() !== "") {
          const commentDate = data.ratedAt
            ? data.ratedAt.toDate
              ? data.ratedAt.toDate().toISOString()
              : new Date(data.ratedAt).toISOString()
            : new Date().toISOString();

          // Get user information with multiple fallback strategies
          const userId = data.userId || "anonymous";
          let userName = "Anonymous User";

          // Try to find user profile by userId
          if (userProfilesMap[userId]) {
            userName = userProfilesMap[userId].displayName;
          }
          // If not found and we have userEmail, try to find by email
          else if (data.userEmail) {
            const profileByEmail = Object.values(userProfilesMap).find(
              (profile) => profile.email === data.userEmail
            );
            if (profileByEmail) {
              userName = profileByEmail.displayName;
            } else {
              // Use email as display name if no profile found
              userName = data.userEmail.split("@")[0]; // Use part before @ as name
            }
          }

          comments.push({
            id: doc.id,
            comment: data.comment,
            presentationRating: data.presentationRating || 0,
            presenterRating: data.presenterRating || 0,
            date: commentDate,
            userId: userId,
            userEmail: data.userEmail || "anonymous",
            userName: userName,
          });
        }
      });

      // Sort comments by date client-side (most recent first)
      comments.sort((a, b) => new Date(b.date) - new Date(a.date));

      return comments;
    } catch (error) {
      console.error("Error fetching presentation comments:", error);
      return [];
    }
  }

  // Get presentation statistics for analytics
  static async getPresentationAnalytics() {
    try {
      const presentations = await this.getAllPresentations();

      const totalPresentations = presentations.length;
      const ratedPresentations = presentations.filter(
        (p) => p.hasRating
      ).length;
      const presentationsWithComments = presentations.filter(
        (p) => p.hasComment
      ).length;
      const keynotePresentations = presentations.filter(
        (p) => p.isKeynote
      ).length;

      const avgPresenterRating = presentations
        .filter((p) => p.presenterRating)
        .reduce((sum, p, _, arr) => sum + p.presenterRating / arr.length, 0);

      const avgPresentationRating = presentations
        .filter((p) => p.presentationRating)
        .reduce((sum, p, _, arr) => sum + p.presentationRating / arr.length, 0);

      return {
        totalPresentations,
        ratedPresentations,
        presentationsWithComments,
        keynotePresentations,
        avgPresenterRating:
          avgPresenterRating > 0 ? Number(avgPresenterRating.toFixed(1)) : 0,
        avgPresentationRating:
          avgPresentationRating > 0
            ? Number(avgPresentationRating.toFixed(1))
            : 0,
        ratingParticipationRate:
          totalPresentations > 0
            ? Math.round((ratedPresentations / totalPresentations) * 100)
            : 0,
      };
    } catch (error) {
      console.error("Error fetching presentation analytics:", error);
      return {
        totalPresentations: 0,
        ratedPresentations: 0,
        presentationsWithComments: 0,
        keynotePresentations: 0,
        avgPresenterRating: 0,
        avgPresentationRating: 0,
        ratingParticipationRate: 0,
      };
    }
  }

  // Helper method to generate consistent presentation ID (same as Flutter app)
  static _generatePresentationId(conference, sessionDate) {
    const title = conference.title || "";
    const presenter = conference.presenter || "";
    const start = conference.start || "";
    const date = sessionDate || "unknown";

    const id = `${title}_${presenter}_${start}_${date}`
      .replace(/\s/g, "_") // Replace spaces with underscores
      .replace(/:/g, "") // Remove colons
      .replace(/-/g, "") // Remove dashes
      .toLowerCase(); // Convert to lowercase

    return id;
  }
}

export default StatisticsService;

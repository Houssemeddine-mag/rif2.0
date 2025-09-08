import {
  collection,
  getDocs,
  getDoc,
  doc,
  addDoc,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "../firebase.js";

class StatisticsService {
  static programsCollection = collection(db, "programs");
  static usersCollection = collection(db, "users");
  static userProfilesCollection = collection(db, "user_profiles");

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

  // Get all presentations with their ratings and comments
  static async getPresentationStatistics() {
    try {
      const programsSnapshot = await getDocs(this.programsCollection);
      const presentations = [];

      programsSnapshot.docs.forEach((doc) => {
        const program = doc.data();
        if (program.conferences && Array.isArray(program.conferences)) {
          program.conferences.forEach((conference, index) => {
            presentations.push({
              id: `${doc.id}_${index}`,
              programId: doc.id,
              programTitle: program.title,
              programDate: program.date,
              title: conference.title,
              presenter: conference.presenter,
              affiliation: conference.affiliation,
              start: conference.start,
              end: conference.end,
              isKeynote: conference.isKeynote || false,
              presenterRating: conference.presenterRating || null,
              presentationRating: conference.presentationRating || null,
              comment: conference.comment || null,
              hasRating: !!(
                conference.presenterRating || conference.presentationRating
              ),
              hasComment: !!conference.comment,
            });
          });
        }
      });

      return presentations;
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

  // Get all comments and feedback
  static async getAllComments() {
    try {
      const presentations = await this.getPresentationStatistics();

      const comments = presentations
        .filter(
          (presentation) =>
            presentation.comment && presentation.comment.trim() !== ""
        )
        .map((presentation) => ({
          id: presentation.id,
          presentationTitle: presentation.title,
          presenter: presentation.presenter,
          programTitle: presentation.programTitle,
          programDate: presentation.programDate,
          comment: presentation.comment,
          presenterRating: presentation.presenterRating,
          presentationRating: presentation.presentationRating,
        }))
        .sort((a, b) => new Date(b.programDate) - new Date(a.programDate)); // Sort by most recent

      return comments;
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

  // Get all presentations with detailed information
  static async getAllPresentations() {
    try {
      const programsSnapshot = await getDocs(this.programsCollection);
      const presentations = [];

      programsSnapshot.docs.forEach((doc) => {
        const program = doc.data();

        if (program.conferences && Array.isArray(program.conferences)) {
          program.conferences.forEach((conference, index) => {
            const presentationId = `${doc.id}_${index}`;

            // Calculate average ratings
            const presenterRating = conference.presenterRating || null;
            const presentationRating = conference.presentationRating || null;
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
              comment: conference.comment,
              commentCount: conference.comment ? 1 : 0, // For now, single comment per presentation
              ratingCount: presenterRating || presentationRating ? 1 : 0, // For now, single rating per presentation
              hasRating: !!(presenterRating || presentationRating),
              hasComment: !!conference.comment,
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

  // Get comments for a specific presentation
  static async getPresentationComments(presentationId) {
    try {
      // Parse presentation ID to get program ID and conference index
      const [programId, conferenceIndex] = presentationId.split("_");

      const programDoc = await getDoc(doc(this.programsCollection, programId));
      if (!programDoc.exists()) {
        return [];
      }

      const program = programDoc.data();
      const conference = program.conferences?.[parseInt(conferenceIndex)];

      if (!conference || !conference.comment) {
        return [];
      }

      // For now, return single comment as array
      // In future, you might want to store multiple comments in a separate collection
      return [
        {
          id: `${presentationId}_comment_1`,
          comment: conference.comment,
          presentationRating: conference.presentationRating,
          presenterRating: conference.presenterRating,
          date: new Date().toISOString(), // You might want to store actual comment dates
          userId: "anonymous", // You might want to store actual user IDs
        },
      ];
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
}

export default StatisticsService;

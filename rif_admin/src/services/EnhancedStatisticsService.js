import { collection, getDocs, query, where, orderBy } from "firebase/firestore";
import { db } from "../firebase.js";

class EnhancedStatisticsService {
  static programsCollection = collection(db, "programs");
  static usersCollection = collection(db, "users");
  static userProfilesCollection = collection(db, "user_profiles");
  static ratingsCollection = collection(db, "ratings");
  static presentationAnalyticsCollection = collection(
    db,
    "presentation_analytics"
  );

  // Get all individual user ratings
  static async getAllUserRatings() {
    try {
      const ratingsSnapshot = await getDocs(this.ratingsCollection);
      const ratings = [];

      ratingsSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        ratings.push({
          id: doc.id,
          userId: data.userId,
          userEmail: data.userEmail,
          presentationId: data.presentationId,
          conferenceTitle: data.conferenceTitle,
          presenter: data.presenter,
          startTime: data.startTime,
          date: data.date,
          presenterRating: data.presenterRating,
          presentationRating: data.presentationRating,
          comment: data.comment,
          ratedAt: data.ratedAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
        });
      });

      return ratings.sort((a, b) => b.ratedAt - a.ratedAt);
    } catch (error) {
      console.error("Error fetching user ratings:", error);
      return [];
    }
  }

  // Get presentation analytics (aggregated data)
  static async getPresentationAnalytics() {
    try {
      const analyticsSnapshot = await getDocs(
        this.presentationAnalyticsCollection
      );
      const analytics = [];

      analyticsSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        analytics.push({
          id: doc.id,
          presentationId: data.presentationId,
          conferenceTitle: data.conferenceTitle,
          presenter: data.presenter,
          startTime: data.startTime,
          date: data.date,
          averagePresenterRating: data.averagePresenterRating,
          averagePresentationRating: data.averagePresentationRating,
          totalRatings: data.totalRatings,
          totalComments: data.totalComments,
          presenterRatingDistribution: data.presenterRatingDistribution || {},
          presentationRatingDistribution:
            data.presentationRatingDistribution || {},
          lastUpdated: data.lastUpdated?.toDate() || new Date(),
        });
      });

      return analytics.sort(
        (a, b) => b.averagePresenterRating - a.averagePresenterRating
      );
    } catch (error) {
      console.error("Error fetching presentation analytics:", error);
      return [];
    }
  }

  // Get top-rated presenters based on individual ratings
  static async getTopRatedPresenters(limitCount = 10) {
    try {
      const analytics = await this.getPresentationAnalytics();
      const presenterStats = {};

      // Aggregate analytics by presenter
      analytics.forEach((presentation) => {
        const presenter = presentation.presenter;
        if (!presenterStats[presenter]) {
          presenterStats[presenter] = {
            name: presenter,
            presentations: [],
            totalRatings: 0,
            totalRatingSum: 0,
            totalPresentations: 0,
          };
        }

        presenterStats[presenter].presentations.push(presentation);
        presenterStats[presenter].totalRatings += presentation.totalRatings;
        presenterStats[presenter].totalRatingSum +=
          presentation.averagePresenterRating * presentation.totalRatings;
        presenterStats[presenter].totalPresentations++;
      });

      // Calculate overall average ratings for each presenter
      const topPresenters = Object.values(presenterStats)
        .map((presenter) => {
          const averageRating =
            presenter.totalRatings > 0
              ? presenter.totalRatingSum / presenter.totalRatings
              : 0;

          return {
            name: presenter.name,
            averageRating: parseFloat(averageRating.toFixed(1)),
            totalRatings: presenter.totalRatings,
            totalPresentations: presenter.totalPresentations,
            presentations: presenter.presentations,
            // Calculate rating distribution across all presentations
            ratingDistribution: presenter.presentations.reduce((acc, p) => {
              Object.keys(p.presenterRatingDistribution).forEach((rating) => {
                acc[rating] =
                  (acc[rating] || 0) + p.presenterRatingDistribution[rating];
              });
              return acc;
            }, {}),
          };
        })
        .filter((presenter) => presenter.averageRating > 0)
        .sort((a, b) => {
          // Sort by average rating first, then by total ratings
          if (b.averageRating !== a.averageRating) {
            return b.averageRating - a.averageRating;
          }
          return b.totalRatings - a.totalRatings;
        })
        .slice(0, limitCount);

      return topPresenters;
    } catch (error) {
      console.error("Error fetching top presenters:", error);
      return [];
    }
  }

  // Get top-rated presentations based on individual ratings
  static async getTopRatedPresentations(limitCount = 10) {
    try {
      const analytics = await this.getPresentationAnalytics();

      const topPresentations = analytics
        .filter((presentation) => presentation.totalRatings > 0)
        .sort((a, b) => {
          // Sort by average presentation rating first, then by total ratings
          if (b.averagePresentationRating !== a.averagePresentationRating) {
            return b.averagePresentationRating - a.averagePresentationRating;
          }
          return b.totalRatings - a.totalRatings;
        })
        .slice(0, limitCount)
        .map((presentation) => ({
          ...presentation,
          overallRating:
            (presentation.averagePresenterRating +
              presentation.averagePresentationRating) /
            2,
        }));

      return topPresentations;
    } catch (error) {
      console.error("Error fetching top presentations:", error);
      return [];
    }
  }

  // Get all comments from individual ratings
  static async getAllComments() {
    try {
      const ratings = await this.getAllUserRatings();

      const comments = ratings
        .filter((rating) => rating.comment && rating.comment.trim() !== "")
        .map((rating) => ({
          id: rating.id,
          presentationTitle: rating.conferenceTitle,
          presenter: rating.presenter,
          date: rating.date,
          comment: rating.comment,
          presenterRating: rating.presenterRating,
          presentationRating: rating.presentationRating,
          userEmail: rating.userEmail,
          ratedAt: rating.ratedAt,
          updatedAt: rating.updatedAt,
        }))
        .sort((a, b) => b.ratedAt - a.ratedAt);

      return comments;
    } catch (error) {
      console.error("Error fetching comments:", error);
      return [];
    }
  }

  // Get ratings for a specific presentation
  static async getPresentationRatings(presentationId) {
    try {
      const q = query(
        this.ratingsCollection,
        where("presentationId", "==", presentationId),
        orderBy("ratedAt", "desc")
      );

      const ratingsSnapshot = await getDocs(q);
      const ratings = [];

      ratingsSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        ratings.push({
          id: doc.id,
          userId: data.userId,
          userEmail: data.userEmail,
          presenterRating: data.presenterRating,
          presentationRating: data.presentationRating,
          comment: data.comment,
          ratedAt: data.ratedAt?.toDate() || new Date(),
          updatedAt: data.updatedAt?.toDate() || new Date(),
        });
      });

      return ratings;
    } catch (error) {
      console.error("Error fetching presentation ratings:", error);
      return [];
    }
  }

  // Get overall statistics with individual rating system
  static async getOverallStatistics() {
    try {
      const [ratings, analytics, programs, userStats] = await Promise.all([
        this.getAllUserRatings(),
        this.getPresentationAnalytics(),
        getDocs(this.programsCollection),
        this.getTotalUsers(),
      ]);

      // Count total presentations from programs
      let totalPresentations = 0;
      let uniquePresenters = new Set();
      let keynoteCount = 0;

      programs.docs.forEach((doc) => {
        const program = doc.data();
        if (program.conferences && Array.isArray(program.conferences)) {
          totalPresentations += program.conferences.length;
          program.conferences.forEach((conference) => {
            uniquePresenters.add(conference.presenter);
            if (conference.isKeynote) {
              keynoteCount++;
            }
          });
        }
      });

      const totalUniqueUsers = new Set(ratings.map((r) => r.userId)).size;
      const ratedPresentations = analytics.length;
      const presentationsWithComments = analytics.filter(
        (a) => a.totalComments > 0
      ).length;

      // Calculate overall average ratings
      const avgPresenterRating =
        analytics.length > 0
          ? analytics.reduce((sum, a) => sum + a.averagePresenterRating, 0) /
            analytics.length
          : 0;

      const avgPresentationRating =
        analytics.length > 0
          ? analytics.reduce((sum, a) => sum + a.averagePresentationRating, 0) /
            analytics.length
          : 0;

      const totalRatingsCount = analytics.reduce(
        (sum, a) => sum + a.totalRatings,
        0
      );

      return {
        // User statistics
        totalUsers: userStats.totalUsers,
        totalAuthUsers: userStats.totalAuthUsers,
        totalProfileUsers: userStats.totalProfileUsers,
        activeRatingUsers: totalUniqueUsers,

        // Presentation statistics
        totalPresentations,
        ratedPresentations,
        presentationsWithComments,
        uniquePresenters: uniquePresenters.size,
        keynoteCount,

        // Rating statistics
        totalIndividualRatings: totalRatingsCount,
        totalComments: ratings.filter((r) => r.comment && r.comment.trim())
          .length,
        avgPresenterRating: parseFloat(avgPresenterRating.toFixed(1)),
        avgPresentationRating: parseFloat(avgPresentationRating.toFixed(1)),

        // Participation rates
        ratingParticipationRate:
          totalPresentations > 0
            ? parseFloat(
                ((ratedPresentations / totalPresentations) * 100).toFixed(1)
              )
            : 0,
        userParticipationRate:
          userStats.totalUsers > 0
            ? parseFloat(
                ((totalUniqueUsers / userStats.totalUsers) * 100).toFixed(1)
              )
            : 0,

        // Rating distribution
        ratingDistribution: this.calculateOverallRatingDistribution(analytics),
      };
    } catch (error) {
      console.error("Error fetching overall statistics:", error);
      return {
        totalUsers: 0,
        totalAuthUsers: 0,
        totalProfileUsers: 0,
        activeRatingUsers: 0,
        totalPresentations: 0,
        ratedPresentations: 0,
        presentationsWithComments: 0,
        uniquePresenters: 0,
        keynoteCount: 0,
        totalIndividualRatings: 0,
        totalComments: 0,
        avgPresenterRating: 0,
        avgPresentationRating: 0,
        ratingParticipationRate: 0,
        userParticipationRate: 0,
        ratingDistribution: { presenter: {}, presentation: {} },
      };
    }
  }

  // Calculate overall rating distribution across all presentations
  static calculateOverallRatingDistribution(analytics) {
    const presenterDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    const presentationDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };

    analytics.forEach((analytic) => {
      // Aggregate presenter ratings
      Object.keys(analytic.presenterRatingDistribution).forEach((rating) => {
        if (
          Object.prototype.hasOwnProperty.call(presenterDistribution, rating)
        ) {
          presenterDistribution[rating] +=
            analytic.presenterRatingDistribution[rating];
        }
      });

      // Aggregate presentation ratings
      Object.keys(analytic.presentationRatingDistribution).forEach((rating) => {
        if (
          Object.prototype.hasOwnProperty.call(presentationDistribution, rating)
        ) {
          presentationDistribution[rating] +=
            analytic.presentationRatingDistribution[rating];
        }
      });
    });

    return {
      presenter: presenterDistribution,
      presentation: presentationDistribution,
    };
  }

  // Get user statistics (reuse from original service)
  static async getTotalUsers() {
    try {
      const usersSnapshot = await getDocs(this.usersCollection);
      const userProfilesSnapshot = await getDocs(this.userProfilesCollection);

      const usersFromAuth = usersSnapshot.size;
      const usersFromProfiles = userProfilesSnapshot.size;

      return {
        totalAuthUsers: usersFromAuth,
        totalProfileUsers: usersFromProfiles,
        totalUsers: Math.max(usersFromAuth, usersFromProfiles),
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

  // Compatibility method: Get all presentations with new rating system
  static async getAllPresentations() {
    try {
      const [programs, analytics] = await Promise.all([
        getDocs(this.programsCollection),
        this.getPresentationAnalytics(),
      ]);

      const presentations = [];

      // Create analytics lookup map
      const analyticsMap = {};
      analytics.forEach((analytic) => {
        analyticsMap[analytic.presentationId] = analytic;
      });

      programs.docs.forEach((doc) => {
        const program = doc.data();
        if (program.conferences && Array.isArray(program.conferences)) {
          program.conferences.forEach((conference, index) => {
            // Generate presentation ID same way as in Firebase service
            const presentationId =
              `${conference.title}_${conference.presenter}_${conference.start}_${program.date}`
                .replaceAll(" ", "_")
                .replaceAll(":", "")
                .replaceAll("-", "")
                .toLowerCase();

            const analytic = analyticsMap[presentationId];

            presentations.push({
              id: `${doc.id}_${index}`,
              presentationId: presentationId,
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

              // New rating system data
              presenterRating: analytic?.averagePresenterRating || null,
              presentationRating: analytic?.averagePresentationRating || null,
              averageRating: analytic
                ? (analytic.averagePresenterRating +
                    analytic.averagePresentationRating) /
                  2
                : null,

              totalRatings: analytic?.totalRatings || 0,
              totalComments: analytic?.totalComments || 0,
              ratingDistribution: {
                presenter: analytic?.presenterRatingDistribution || {},
                presentation: analytic?.presentationRatingDistribution || {},
              },

              hasRating: !!(analytic?.totalRatings > 0),
              hasComment: !!(analytic?.totalComments > 0),

              // Legacy compatibility fields
              commentCount: analytic?.totalComments || 0,
              ratingCount: analytic?.totalRatings || 0,
            });
          });
        }
      });

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

  // Get detailed user engagement statistics
  static async getUserEngagementStats() {
    try {
      const ratings = await this.getAllUserRatings();
      const userStats = {};

      ratings.forEach((rating) => {
        if (!userStats[rating.userId]) {
          userStats[rating.userId] = {
            userId: rating.userId,
            userEmail: rating.userEmail,
            totalRatings: 0,
            totalComments: 0,
            presentations: [],
            avgPresenterRating: 0,
            avgPresentationRating: 0,
            lastActivity: rating.ratedAt,
          };
        }

        const user = userStats[rating.userId];
        user.totalRatings++;
        if (rating.comment && rating.comment.trim()) {
          user.totalComments++;
        }
        user.presentations.push({
          presentationTitle: rating.conferenceTitle,
          presenter: rating.presenter,
          presenterRating: rating.presenterRating,
          presentationRating: rating.presentationRating,
          ratedAt: rating.ratedAt,
        });

        if (rating.ratedAt > user.lastActivity) {
          user.lastActivity = rating.ratedAt;
        }
      });

      // Calculate averages for each user
      Object.values(userStats).forEach((user) => {
        const presenterRatings = user.presentations.map(
          (p) => p.presenterRating
        );
        const presentationRatings = user.presentations.map(
          (p) => p.presentationRating
        );

        user.avgPresenterRating =
          presenterRatings.length > 0
            ? presenterRatings.reduce((sum, r) => sum + r, 0) /
              presenterRatings.length
            : 0;

        user.avgPresentationRating =
          presentationRatings.length > 0
            ? presentationRatings.reduce((sum, r) => sum + r, 0) /
              presentationRatings.length
            : 0;

        user.avgPresenterRating = parseFloat(
          user.avgPresenterRating.toFixed(1)
        );
        user.avgPresentationRating = parseFloat(
          user.avgPresentationRating.toFixed(1)
        );
      });

      return Object.values(userStats).sort(
        (a, b) => b.totalRatings - a.totalRatings
      );
    } catch (error) {
      console.error("Error fetching user engagement stats:", error);
      return [];
    }
  }

  // Legacy compatibility methods (delegate to original service for non-rating features)
  static async getUserProfiles() {
    // Import original service for this method
    const { default: StatisticsService } = await import(
      "./StatisticsService.js"
    );
    return StatisticsService.getUserProfiles();
  }

  static async getAuthUsers() {
    const { default: StatisticsService } = await import(
      "./StatisticsService.js"
    );
    return StatisticsService.getAuthUsers();
  }

  static async getUserRegistrationStats() {
    const { default: StatisticsService } = await import(
      "./StatisticsService.js"
    );
    return StatisticsService.getUserRegistrationStats();
  }

  static async notifyIncompleteProfileUsers() {
    const { default: StatisticsService } = await import(
      "./StatisticsService.js"
    );
    return StatisticsService.notifyIncompleteProfileUsers();
  }
}

export default EnhancedStatisticsService;

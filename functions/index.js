const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");
const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

admin.initializeApp();

// ─────────────────────────────────────────
// 1. onUserCreated
// Trigger: new Auth user registered
// Action: creates their Firestore user doc
// ─────────────────────────────────────────
/* exports.onUserCreated = functionsV1.auth.user().onCreate(async (user) => {
    await db.collection("users").doc(user.uid).set({
        userId:             user.uid,
        name:               "",
        email:              user.email ?? "",
        department:         "",
        registrationNumber: "",
        bio:                "",
        profilePhotoUrl:    "",
        rating:             0,
        totalRatings:       0,
        completedGigs:      0,
        completedRentals:   0,
        cancellations:      0,
        reportCount:        0,
        role:               "student",
        verificationStatus: "unverified",
        isSuspended:        false,
        isBanned:           false,
        activeGigIds:       [],
        activeRentalIds:    [],
        createdAt:          admin.firestore.FieldValue.serverTimestamp(),
        lastActiveAt:       null,
    });
});

removed because don't need it. 
the SetupProfileScreen already creates the user document in Firestore 
when the user completes profile setup. The Cloud Function was a redundant safety net.
*/

// ─────────────────────────────────────────
// 2. onGigStatusChange
// Trigger: any gig document updated
// Action: sends notification based on new status
// ─────────────────────────────────────────
exports.onGigStatusChange = onDocumentUpdated(
    { document: "gigs/{gigId}", database: "(default)", region: "asia-south1" },
    async (event) => {
        const before = event.data.before.data();
        const after = event.data.after.data();
        const gigId = event.params.gigId;

        if (before.status === after.status) return null;

        let targetUserId = null;
        let title = "";
        let body = "";

        switch (after.status) {
            case "accepted":
                targetUserId = after.creatorId;
                title = "Gig Accepted";
                body = `Your gig "${after.title}" has been accepted.`;
                break;
            case "inProgress":
                targetUserId = after.creatorId;
                title = "Gig Started";
                body = `Work has started on your gig "${after.title}".`;
                break;
            case "completedPendingReview":
                targetUserId = after.creatorId;
                title = "Gig Completed";
                body = `"${after.title}" is marked complete. Please review.`;
                break;
            case "closed":
                targetUserId = after.acceptedById;
                title = "Gig Closed";
                body = `Gig "${after.title}" has been closed. Check your rating.`;
                break;
            case "cancelled":
                targetUserId = after.acceptedById ?? after.creatorId;
                title = "Gig Cancelled";
                body = `Gig "${after.title}" has been cancelled.`;
                break;
        }

        if (!targetUserId) return null;

        return db
            .collection("notifications")
            .doc(targetUserId)
            .collection("items")
            .add({
                type: `gig_${after.status}`,
                title,
                body,
                targetId: gigId,
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
    }
);

// ─────────────────────────────────────────
// 3. onRentalStatusChange
// Trigger: any rental document updated
// Action: sends notification based on new status
// ─────────────────────────────────────────
exports.onRentalStatusChange = onDocumentUpdated(
    { document: "rentals/{rentalId}", database: "(default)", region: "asia-south1" },
    async (event) => {
        const before = event.data.before.data();
        const after = event.data.after.data();
        const rentalId = event.params.rentalId;

        if (before.status === after.status) return null;

        let targetUserId = null;
        let title = "";
        let body = "";

        switch (after.status) {
            case "requested":
                targetUserId = after.ownerId;
                title = "Rental Requested";
                body = `Someone wants to rent your "${after.itemName}".`;
                break;
            case "active":
                targetUserId = after.renterId;
                title = "Rental Approved";
                body = `Your rental request for "${after.itemName}" was approved.`;
                break;
            case "returnPending":
                targetUserId = after.ownerId;
                title = "Return Initiated";
                body = `"${after.itemName}" is being returned. Please confirm.`;
                break;
            case "completed":
                targetUserId = after.renterId;
                title = "Rental Completed";
                body = `Your rental of "${after.itemName}" is complete. Leave a rating.`;
                break;
            case "cancelled":
                targetUserId = after.ownerId;
                title = "Rental Cancelled";
                body = `Rental for "${after.itemName}" has been cancelled.`;
                break;
            case "disputed":
                targetUserId = after.ownerId;
                title = "Dispute Raised";
                body = `A dispute was raised on "${after.itemName}".`;
                break;
        }

        if (!targetUserId) return null;

        return db
            .collection("notifications")
            .doc(targetUserId)
            .collection("items")
            .add({
                type: `rental_${after.status}`,
                title,
                body,
                targetId: rentalId,
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
    }
);

// ─────────────────────────────────────────
// 4. onRatingCreated
// Trigger: new rating document created
// Action: recalculates target user's average rating
// ─────────────────────────────────────────
exports.onRatingCreated = onDocumentCreated(
    { document: "reviews/{reviewId}", database: "(default)", region: "asia-south1" },
    async (event) => {
        const review = event.data.data();
        const targetUserId = review.targetId;

        const snap = await db
            .collection("reviews")
            .where("targetId", "==", targetUserId)
            .get();

        const total = snap.docs.reduce((sum, doc) => sum + doc.data().rating, 0);
        const average = total / snap.docs.length;

        return db.collection("users").doc(targetUserId).update({
            rating: Math.round(average * 10) / 10,
            totalRatings: snap.docs.length,
        });
    }
);

// ─────────────────────────────────────────
// 5. onReportCreated
// Trigger: new report document created
// Action: increments reportCount, auto-suspends at 5
// ─────────────────────────────────────────
exports.onReportCreated = onDocumentCreated(
    { document: "reports/{reportId}", database: "(default)", region: "asia-south1" },
    async (event) => {
        const report = event.data.data();

        if (report.targetType !== "user") return null;

        const userRef = db.collection("users").doc(report.targetId);
        const userSnap = await userRef.get();

        if (!userSnap.exists) return null;

        const newCount = (userSnap.data().reportCount || 0) + 1;
        const update = { reportCount: newCount };

        if (newCount >= 5) {
            update.isSuspended = true;
        }

        return userRef.update(update);
    }
);

// ─────────────────────────────────────────
// 6. onGigDeadlineExpiry
// Trigger: runs every day at midnight IST
// Action: auto-cancels OPEN gigs past deadline
// ─────────────────────────────────────────
exports.onGigDeadlineExpiry = onSchedule(
    { schedule: "every 24 hours", region: "asia-south1" },
    async () => {
        const now = admin.firestore.Timestamp.now();

        const expiredGigs = await db
            .collection("gigs")
            .where("status", "==", "open")
            .where("deadline", "<", now)
            .get();

        if (expiredGigs.empty) return;

        const batch = db.batch();
        expiredGigs.docs.forEach((doc) => {
            batch.update(doc.ref, { status: "cancelled" });
        });

        return batch.commit();
    }
);
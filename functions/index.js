const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");
const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { beforeUserCreated } = require("firebase-functions/v2/identity");

admin.initializeApp();
const db = getFirestore("default");

// ─────────────────────────────────────────
// 1. onUserCreated
// Trigger: new Auth user registered
// Action: creates their Firestore user doc
// ─────────────────────────────────────────
exports.onUserCreated = beforeUserCreated(async (event) => {
    const user = event.data;
    await db.collection("users").doc(user.uid).set({
        name: "",
        email: user.email,
        department: "",
        bio: "",
        skills: [],
        rating: 0,
        completedGigs: 0,
        completedRentals: 0,
        cancellationCount: 0,
        reportCount: 0,
        isVerified: false,
        isSuspended: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});

// ─────────────────────────────────────────
// 2. onGigStatusChange
// Trigger: any gig document updated
// Action: sends notification based on new status
// ─────────────────────────────────────────
exports.onGigStatusChange = onDocumentUpdated(
    { document: "gigs/{gigId}", database: "default" },
    async (event) => {
        const before = event.data.before.data();
        const after = event.data.after.data();
        const gigId = event.params.gigId;

        if (before.status === after.status) return null;

        let targetUserId = null;
        let title = "";
        let body = "";

        if (after.status === "ACCEPTED") {
            targetUserId = after.createdBy;
            title = "Gig Accepted";
            body = `Your gig "${after.title}" has been accepted.`;
        } else if (after.status === "IN_PROGRESS") {
            targetUserId = after.createdBy;
            title = "Gig Started";
            body = `Work has started on your gig "${after.title}".`;
        } else if (after.status === "COMPLETED_PENDING_REVIEW") {
            targetUserId = after.createdBy;
            title = "Gig Completed";
            body = `"${after.title}" is marked complete. Please review.`;
        } else if (after.status === "CLOSED") {
            targetUserId = after.acceptedBy;
            title = "Gig Closed";
            body = `Gig "${after.title}" has been closed. Check your rating.`;
        } else if (after.status === "CANCELLED") {
            targetUserId = after.acceptedBy || after.createdBy;
            title = "Gig Cancelled";
            body = `Gig "${after.title}" has been cancelled.`;
        }

        if (!targetUserId) return null;

        return db.collection("notifications").add({
            userId: targetUserId,
            title,
            body,
            type: `GIG_${after.status}`,
            refId: gigId,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

// ─────────────────────────────────────────
// 3. onRentalStatusChange
// Trigger: any rental document updated
// Action: sends notification based on new status
// ─────────────────────────────────────────
exports.onRentalStatusChange = onDocumentUpdated(
    { document: "rentals/{rentalId}", database: "default" },
    async (event) => {
        const before = event.data.before.data();
        const after = event.data.after.data();
        const rentalId = event.params.rentalId;

        if (before.status === after.status) return null;

        let targetUserId = null;
        let title = "";
        let body = "";

        if (after.status === "REQUESTED") {
            targetUserId = after.ownerId;
            title = "Rental Requested";
            body = `Someone has requested to rent your item "${after.itemName}".`;
        } else if (after.status === "ACTIVE") {
            targetUserId = after.renterId;
            title = "Rental Approved";
            body = `Your rental request for "${after.itemName}" was approved.`;
        } else if (after.status === "RETURN_PENDING") {
            targetUserId = after.ownerId;
            title = "Return Initiated";
            body = `"${after.itemName}" is being returned. Please confirm.`;
        } else if (after.status === "COMPLETED") {
            targetUserId = after.renterId;
            title = "Rental Completed";
            body = `Your rental of "${after.itemName}" is complete. Leave a rating.`;
        } else if (after.status === "CANCELLED") {
            targetUserId = after.ownerId;
            title = "Rental Cancelled";
            body = `Rental for "${after.itemName}" has been cancelled.`;
        } else if (after.status === "DISPUTED") {
            targetUserId = after.ownerId;
            title = "Dispute Raised";
            body = `A dispute was raised on rental "${after.itemName}".`;
        }

        if (!targetUserId) return null;

        return db.collection("notifications").add({
            userId: targetUserId,
            title,
            body,
            type: `RENTAL_${after.status}`,
            refId: rentalId,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

// ─────────────────────────────────────────
// 4. onRatingCreated
// Trigger: new rating document created
// Action: recalculates target user's average rating
// ─────────────────────────────────────────
exports.onRatingCreated = onDocumentCreated(
    { document: "ratings/{ratingId}", database: "default" },
    async (event) => {
        const rating = event.data.data();
        const targetUserId = rating.toUserId;

        const ratingsSnap = await db
            .collection("ratings")
            .where("toUserId", "==", targetUserId)
            .get();

        const total = ratingsSnap.docs.reduce((sum, doc) => sum + doc.data().stars, 0);
        const average = total / ratingsSnap.docs.length;

        return db.collection("users").doc(targetUserId).update({
            rating: Math.round(average * 10) / 10,
        });
    });

// ─────────────────────────────────────────
// 5. onReportCreated
// Trigger: new report document created
// Action: increments reportCount, auto-flags at threshold
// ─────────────────────────────────────────
exports.onReportCreated = onDocumentCreated(
    { document: "reports/{reportId}", database: "default" },
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
    });

// ─────────────────────────────────────────
// 6. onGigDeadlineExpiry
// Trigger: runs every day at midnight
// Action: auto-cancels OPEN gigs past their deadline
// ─────────────────────────────────────────
exports.onGigDeadlineExpiry = onSchedule("every 24 hours", async () => {
    const now = admin.firestore.Timestamp.now();

    const expiredGigs = await db
        .collection("gigs")
        .where("status", "==", "OPEN")
        .where("deadline", "<", now)
        .get();

    const batch = db.batch();

    expiredGigs.docs.forEach((doc) => {
        batch.update(doc.ref, { status: "CANCELLED" });
    });

    return batch.commit();
});
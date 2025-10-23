const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.onMessageCreated = functions.firestore
    .document("conversations/{conversationId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const conversationId = context.params.conversationId;

        if (!message || !message.senderId || !conversationId) {
            console.warn("Skipping push, incomplete message payload", message);
            return null;
        }

        const conversationSnap = await db
            .collection("conversations")
            .doc(conversationId)
            .get();

        if (!conversationSnap.exists) {
            console.warn("Conversation not found for push", conversationId);
            return null;
        }

        const conversation = conversationSnap.data();
        const participantIds = conversation.participants || [];
        const senderId = message.senderId;

        const recipientIds = participantIds.filter((id) => id !== senderId);
        if (recipientIds.length === 0) {
            console.info("No recipients for push", conversationId);
            return null;
        }

        const tokenResults = await Promise.all(
            recipientIds.map(async (userId) => {
                try {
                    const doc = await db.collection("users").doc(userId).get();
                    if (!doc.exists) {
                        console.warn("Recipient user doc missing", userId);
                        return null;
                    }
                    const data = doc.data();
                    if (data?.fcmToken) {
                        return { userId, token: data.fcmToken };
                    }
                    console.warn("Recipient missing fcmToken", userId);
                    return null;
                } catch (error) {
                    console.error("Error fetching recipient", userId, error);
                    return null;
                }
            })
        );

        const tokens = tokenResults
            .filter((result) => result?.token)
            .map((result) => result.token);

        if (tokens.length === 0) {
            console.info("No valid FCM tokens for recipients", recipientIds);
            return null;
        }

        const senderName = message.senderName || conversation.participantNames?.[senderId] || "Someone";
        const title = conversation.type === "group" ? (conversation.groupName || "Group Chat") : senderName;
        const body = message.text || "Sent a message";

        try {
            const response = await admin.messaging().sendEachForMulticast({
                tokens,
                notification: {
                    title,
                    body,
                },
                data: {
                    conversationId,
                    senderId,
                    messageId: context.params.messageId,
                    type: conversation.type || "direct",
                },
            });

            const failures = response.responses.filter((r) => !r.success);
            if (failures.length) {
                console.warn(
                    "Push failures",
                    failures.map((f) => ({ error: f.error?.message }))
                );
            }
            return null;
        } catch (error) {
            console.error("Error sending push", error);
            return null;
        }
    });

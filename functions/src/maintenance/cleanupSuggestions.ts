import { onRequest } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

export const cleanupDismissedSuggestions = onRequest(async (req, res) => {
  const userId = req.query.userId as string || 'kZZBHhTGufVthIOPqjjzY9nQBpH3';
  
  const db = getFirestore();
  const suggestionsRef = db.collection('users').doc(userId)
    .collection('digest').doc('suggestions')
    .collection('items');
  
  const snapshot = await suggestionsRef.where('status', '==', 'dismissed').get();
  
  console.log(`Found ${snapshot.size} dismissed suggestions to delete`);
  
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    console.log(`  - Deleting: ${doc.id}`);
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  
  res.json({ 
    success: true, 
    deleted: snapshot.size,
    message: `Deleted ${snapshot.size} dismissed suggestions`
  });
});


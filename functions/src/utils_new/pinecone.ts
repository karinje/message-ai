import { Pinecone } from '@pinecone-database/pinecone';

let pineconeClient: Pinecone | null = null;

/**
 * Get Pinecone client singleton
 */
export const getPineconeClient = async (): Promise<Pinecone> => {
  if (!pineconeClient) {
    pineconeClient = new Pinecone({
      apiKey: process.env.PINECONE_API_KEY!,
    });
  }
  return pineconeClient;
};

/**
 * Get Pinecone index
 */
export const getIndex = async () => {
  const client = await getPineconeClient();
  return client.index(process.env.PINECONE_INDEX || 'weftly-messages');
};

/**
 * Embed and upsert message to Pinecone
 */
export const embedMessage = async (message: {
  id: string;
  text: string;
  conversationId: string;
  senderId: string;
  senderName: string;
  timestamp: number;
}) => {
  const index = await getIndex();
  const { generateEmbedding } = await import('./embeddings');
  
  const embedding = await generateEmbedding(message.text);
  
  await index.upsert([{
    id: message.id,
    values: embedding,
    metadata: {
      conversationId: message.conversationId,
      text: message.text,
      senderId: message.senderId,
      senderName: message.senderName,
      timestamp: message.timestamp,
      deletedBy: [], // Array of user IDs who deleted this
    }
  }]);
  
  console.log(`✅ Embedded message ${message.id} to Pinecone`);
};

/**
 * Semantic search (returns message metadata)
 */
export const semanticSearch = async (
  query: string,
  conversationId: string,
  userId: string,
  topK: number = 20
) => {
  const index = await getIndex();
  const { generateEmbedding } = await import('./embeddings');
  
  const embedding = await generateEmbedding(query);
  
  const results = await index.query({
    vector: embedding,
    topK,
    filter: {
      conversationId: { $eq: conversationId },
      deletedBy: { $nin: [userId] } // Exclude messages user deleted
    },
    includeMetadata: true,
  });
  
  return results.matches || [];
};


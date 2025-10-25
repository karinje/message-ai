import OpenAI from "openai";
import * as functions from "firebase-functions";

let openaiClient: OpenAI | null = null;

/**
 * Get or create OpenAI client singleton
 */
export function getOpenAIClient(): OpenAI {
  if (!openaiClient) {
    // Try environment variable first (for .env migration), then fall back to functions.config()
    const apiKey = process.env.OPENAI_API_KEY || functions.config().openai?.api_key;
    if (!apiKey) {
      throw new Error("OpenAI API key not configured. Set it via: firebase functions:config:set openai.api_key=\"YOUR_KEY\"");
    }
    openaiClient = new OpenAI({
      apiKey,
    });
  }
  return openaiClient;
}

/**
 * Create a structured completion with JSON mode
 * @param systemPrompt - The system instructions
 * @param userMessage - The user message
 * @param model - The model to use (default: gpt-4o-mini)
 * @returns Parsed JSON response
 */
export async function createStructuredCompletion<T>(
  systemPrompt: string,
  userMessage: string,
  model: string = "gpt-4o-mini"
): Promise<T> {
  const client = getOpenAIClient();

  try {
    const response = await client.chat.completions.create({
      model,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userMessage },
      ],
      response_format: { type: "json_object" },
      temperature: 0.3, // Lower temperature for more consistent extractions
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error("No response from OpenAI");
    }

    return JSON.parse(content) as T;
  } catch (error) {
    console.error("OpenAI API error:", error);
    throw new Error(`Failed to get structured completion: ${(error as Error).message}`);
  }
}

/**
 * Create a simple chat completion
 * @param systemPrompt - The system instructions
 * @param userMessage - The user message
 * @param model - The model to use (default: gpt-4o-mini)
 * @returns The assistant's response
 */
export async function createChatCompletion(
  systemPrompt: string,
  userMessage: string,
  model: string = "gpt-4o-mini"
): Promise<string> {
  const client = getOpenAIClient();

  try {
    const response = await client.chat.completions.create({
      model,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userMessage },
      ],
      temperature: 0.7,
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error("No response from OpenAI");
    }

    return content;
  } catch (error) {
    console.error("OpenAI API error:", error);
    throw new Error(`Failed to get chat completion: ${(error as Error).message}`);
  }
}

/**
 * Create embeddings for text
 * @param text - The text to embed
 * @param model - The embedding model (default: text-embedding-3-small)
 * @returns The embedding vector
 */
export async function createEmbedding(
  text: string,
  model: string = "text-embedding-3-small"
): Promise<number[]> {
  const client = getOpenAIClient();

  try {
    const response = await client.embeddings.create({
      model,
      input: text,
    });

    return response.data[0].embedding;
  } catch (error) {
    console.error("OpenAI embedding error:", error);
    throw new Error(`Failed to create embedding: ${(error as Error).message}`);
  }
}


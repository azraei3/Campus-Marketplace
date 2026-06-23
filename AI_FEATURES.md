# Campus Marketplace - AI Features Summary

This document summarizes the 6 AI-powered features implemented in the **Campus Marketplace** application. All AI features are designed to enhance security, trust, and user convenience, backed by local rules/template engines to ensure 100% availability during demonstrations.

---

## 1. AI Campus Assistant (RAG Chatbot)
*   **Location:** Home Screen (Floating Purple Icon at the bottom-right).
*   **Primary Files:** 
    *   [`lib/screens/widgets/ai_assistant_sheet.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/screens/widgets/ai_assistant_sheet.dart) (UI bottom sheet, loading states, animation)
    *   [`lib/services/ai_service.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/services/ai_service.dart) (Context packaging and API connection)
*   **How it Works:** 
    *   Uses **Retrieval-Augmented Generation (RAG)** to provide accurate, real-time answers.
    *   When opened, it queries available listings, user profiles (sellers), and ratings from Firestore.
    *   It packages this structured data as a context prompt:
        `LIVE LISTINGS: [Title | Category | Condition | Price | Seller (Verified Status)]`
        `SELLER PROFILES & RATINGS: [Name | Rating | Total Reviews]`
        `RECENT BUYER REVIEWS: [Comment | Score]`
    *   Sends this context along with the user's question to the DeepSeek API.
*   **Fallback:** If the API is unreachable, a local regex-based keyword search runs against the retrieved listings/sellers to answer queries like *"cheapest item"*, *"who is verified"*, or *"is there a bicycle"*.

---

## 2. AI Chat Safety Scanner
*   **Location:** Inside Chat Rooms (Header → Green Lock icon **"AI Scan"**).
*   **Primary Files:** 
    *   [`lib/screens/chats/chat_screen.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/screens/chats/chat_screen.dart) (UI Trigger button and Dialog popup)
    *   [`lib/services/ai_service.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/services/ai_service.dart) (Chat history scan logic)
*   **How it Works:** 
    *   Retrieves the last 15 messages in the active chat conversation.
    *   Evaluates conversational context (asking for bank transfers, off-platform redirects like WhatsApp/Telegram, suspicious urgency, or email exchanges).
    *   Returns a structured evaluation indicating:
        *   `🟢 Safe` (Healthy transaction negotiation)
        *   `🟡 Warning` (Suggesting off-platform chat)
        *   `🔴 Danger` (Scam signals, direct bank transfer requests)
*   **Fallback:** A local parser scanning for critical scam keywords (e.g., *"whatsapp"*, *"telegram"*, *"transfer"*, *"bank account"*, *"deposit"*, *"payme"*) guarantees immediate results if the API is offline.

---

## 3. AI Listing Deal Score
*   **Location:** Product Detail Screen (Automatically loads below listing title and price).
*   **Primary Files:** 
    *   [`lib/screens/listings/listing_detail_screen.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/screens/listings/listing_detail_screen.dart) (Dynamic deal badge UI component)
    *   [`lib/services/ai_service.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/services/ai_service.dart) (Scoring engine)
*   **How it Works:** 
    *   Evaluates the listing's price against its category, condition, saves, and views.
    *   Generates a letter grade (`A+`, `A`, `B`, `C`), a short badge label, and a one-sentence rationale (e.g., *"Priced 20% lower than typical electronics in like-new condition."*).
*   **Fallback:** Relies on a hardcoded fair-price matrix per category (e.g., Electronics fair price = RM 200, Books = RM 40, etc.), modifying the score based on the item's condition rating (Brand New, Like New, Good, Fair).

---

## 4. AI Seller Reputation Summary
*   **Location:** Seller Profile Screen (Purple Card at the top).
*   **Primary Files:** 
    *   [`lib/screens/ratings/seller_profile_screen.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/screens/ratings/seller_profile_screen.dart) (Summary card UI)
    *   [`lib/services/ai_service.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/services/ai_service.dart) (Review summarization logic)
*   **How it Works:** 
    *   Collects all text reviews received by the seller.
    *   Instructs the AI to read the reviews and output a concise, two-sentence summary highlighting the seller's behavior (e.g., *"Prompt and friendly; buyers consistently praise their reliability"*).
*   **Fallback:** Groups ratings by average score to produce templated summaries (e.g., Rating > 4.5 → *"Exceptional seller, highly praised by campus buyers."*).

---

## 5. AI Smart Review Generator
*   **Location:** Submit Review Screen (Tap stars and tags, then click **"AI Write"**).
*   **Primary Files:** 
    *   [`lib/screens/ratings/submit_rating_screen.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/screens/ratings/submit_rating_screen.dart) (Tag chips selection UI and AI Write button)
    *   [`lib/services/ai_service.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/services/ai_service.dart) (Review prompt builder)
*   **How it Works:** 
    *   Takes the rating score (1-5 stars) and user-selected tag chips (e.g., *Friendly*, *Fast Response*, *On Time*, *As Described*).
    *   Generates a realistic review comment using natural, campus-student-like language matching the selected sentiment.
*   **Fallback:** Randomly aggregates selected tags into descriptive template sentences (e.g., *"Great transaction! The seller was friendly and on time. Highly recommended!"*).

---

## 6. AI Copywriter
*   **Location:** Create / Edit Listing form (Button above the Description field).
*   **Primary Files:** 
    *   [`lib/screens/listings/widgets/listing_form.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/screens/listings/widgets/listing_form.dart) (Form UI integration)
    *   [`lib/services/ai_service.dart`](file:///c:/Users/Victus%20by%20HP/Downloads/Campus-Marketplace/lib/services/ai_service.dart) (Description generator)
*   **How it Works:** 
    *   Takes user inputs (Title, Category, Condition, and Price) and prompts the AI to write an engaging description.
    *   Instructs the model to tailor descriptions specifically for university campus meetups.
*   **Fallback:** Generates descriptions using structural templates (e.g., *"Selling this [Title] in [Condition] condition for only RM[Price]. Ideal for campus use. Meet up at UTM."*).

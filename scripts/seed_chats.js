/**
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║         CAMPUS MARKETPLACE — DEMO CHAT SEED SCRIPT (AUTO)              ║
 * ║  Automatically reads real users & listings from your Firestore DB       ║
 * ║  and populates realistic chat conversations for demo purposes.          ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 *
 * HOW TO RUN:
 *   1. cd scripts
 *   2. npm install
 *   3. node seed_chats.js
 */

const admin = require('firebase-admin');
const path = require('path');

// ── Point to the service account key in the root folder ──────────────────────
const serviceAccount = require(path.join(__dirname, '..', 'campusmarketplace-19060-firebase-adminsdk-fbsvc-6de09fb56b.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'campusmarketplace-19060',
});

const db = admin.firestore();

// ─────────────────────────────────────────────────────────────────
// REALISTIC UTM CHAT CONVERSATIONS
// Each scenario is designed to show a different AI Safety Scan result
// ─────────────────────────────────────────────────────────────────
const CHAT_SCRIPTS = [
  // 🟢 SAFE — normal campus meetup (AI Scan → "Safe")
  {
    scenario: 'safe_textbook',
    buyerMsg: (title, price) => [
      { from: 'buyer', text: `Hi! Is "${title}" still available?` },
      { from: 'seller', text: 'Yes it is! Still in great condition.' },
      { from: 'buyer', text: 'Awesome! Does it include all chapters?' },
      { from: 'seller', text: 'Yep, all chapters intact. A few highlights but nothing major.' },
      { from: 'buyer', text: `Can we meet at KTDI tomorrow? Happy to pay RM${Math.round(price)} cash.` },
      { from: 'seller', text: 'Sure! How about 3pm at KTDI foyer near the notice board?' },
      { from: 'buyer', text: 'Perfect, see you then! 👍' },
      { from: 'seller', text: `Great! I'll bring the item. See you at 3pm!` },
    ],
  },
  // 🟡 WARNING — off-platform request (AI Scan → "Warning")
  {
    scenario: 'warning_whatsapp',
    buyerMsg: (title, price) => [
      { from: 'buyer', text: `Hi, interested in "${title}". Still available?` },
      { from: 'seller', text: 'Yes! Good timing.' },
      { from: 'buyer', text: 'Can you drop your WhatsApp? Easier to chat there.' },
      { from: 'seller', text: 'Sure, add me: 011-XXXXXXX. Message me on WhatsApp.' },
      { from: 'buyer', text: 'Alright will do. This is urgent, I need it by Friday.' },
      { from: 'seller', text: `No worries, last chance at RM${Math.round(price)}!` },
      { from: 'buyer', text: `Okay added you. Will finalize there.` },
    ],
  },
  // 🔴 DANGER — scam signals (AI Scan → "Danger")
  {
    scenario: 'danger_deposit_scam',
    buyerMsg: (title, price) => [
      { from: 'buyer', text: `Hi! Is "${title}" still for sale?` },
      { from: 'seller', text: 'Yes! Special deal only for today.' },
      { from: 'buyer', text: 'Can I see it first before buying?' },
      { from: 'seller', text: `I'm not on campus. Transfer RM${Math.round(price * 0.3)} deposit first to my Maybank account to reserve it.` },
      { from: 'buyer', text: 'Hmm, deposit before seeing it? Seems risky.' },
      { from: 'seller', text: 'My bank account number is 1234567890. Payment first then I will ship it to you.' },
      { from: 'buyer', text: `I'm not comfortable paying before a meetup...` },
      { from: 'seller', text: 'Don\'t worry! Transfer the deposit and I promise I will deliver.' },
    ],
  },
  // 🟢 Normal price negotiation (AI Scan → "Safe")
  {
    scenario: 'safe_negotiation',
    buyerMsg: (title, price) => [
      { from: 'buyer', text: `Hi! I love this ${title}. Is the price negotiable?` },
      { from: 'seller', text: `I can go down to RM${Math.round(price * 0.9)}, that's the lowest.` },
      { from: 'buyer', text: `Deal! Where do you stay on campus?` },
      { from: 'seller', text: 'I\'m in KTF college. Can you come Saturday morning?' },
      { from: 'buyer', text: 'Saturday 10am works! I\'ll see you at KTF lobby.' },
      { from: 'seller', text: 'Perfect! See you then 😊' },
    ],
  },
  // 🟢 Completed happy deal (AI Scan → "Safe")
  {
    scenario: 'safe_happy_deal',
    buyerMsg: (title, price) => [
      { from: 'buyer', text: `Hey! Super interested in your "${title}". Is it still available?` },
      { from: 'seller', text: 'Yes! It\'s barely used, only a couple of times.' },
      { from: 'buyer', text: `RM${Math.round(price)} as listed. Let's do it!` },
      { from: 'seller', text: 'Great! Let\'s meet at KDOJ parking lot Thursday 2pm?' },
      { from: 'buyer', text: 'Done! I\'ll be there. Super excited 🎉' },
      { from: 'seller', text: 'Haha glad to hear it! See you Thursday.' },
      { from: 'buyer', text: 'Btw, will you accept cash on the spot?' },
      { from: 'seller', text: 'Of course, cash is perfect. See you there!' },
    ],
  },
];

// ─────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────
function minutesAgo(n) {
  return admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - n * 60 * 1000)
  );
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

// ─────────────────────────────────────────────────────────────────
// MAIN SEEDER — Auto-fetches real users & listings
// ─────────────────────────────────────────────────────────────────
async function seedChats() {
  console.log('\n🌱 Campus Marketplace — Auto Chat Seeder\n');
  console.log('📡 Connecting to Firestore...\n');

  // ── Step 1: Fetch all users ──────────────────────────────────────
  const usersSnap = await db.collection('users').get();
  const users = usersSnap.docs.map(doc => ({
    uid: doc.id,
    name: doc.data().name || 'Unknown User',
  }));

  if (users.length < 2) {
    console.error('❌ Need at least 2 registered users in your app to seed chats.');
    console.error('   Please register at least 2 accounts first, then re-run.\n');
    process.exit(1);
  }

  console.log(`✅ Found ${users.length} users:`);
  users.forEach(u => console.log(`   • ${u.name} (${u.uid})`));

  // ── Step 2: Fetch available listings ────────────────────────────
  const listingsSnap = await db.collection('listings')
    .where('status', '==', 'available')
    .limit(20)
    .get();

  const listings = listingsSnap.docs.map(doc => ({
    id: doc.id,
    title: doc.data().title || 'Item',
    price: doc.data().price || 50,
    sellerId: doc.data().sellerId || '',
    sellerName: doc.data().sellerName || 'Seller',
    imageUrl: doc.data().imageUrl || '',
  })).filter(l => l.sellerId);

  if (listings.length === 0) {
    console.error('\n❌ No available listings found in Firestore.');
    console.error('   Please create at least 1 listing in the app first.\n');
    process.exit(1);
  }

  console.log(`\n✅ Found ${listings.length} listings:`);
  listings.forEach(l => console.log(`   • "${l.title}" (RM${l.price}) by ${l.sellerName}`));

  // ── Step 3: Seed chats ──────────────────────────────────────────
  console.log('\n💬 Creating chat conversations...\n');

  let chatsCreated = 0;
  let messagesCreated = 0;
  let skipped = 0;

  for (let i = 0; i < listings.length; i++) {
    const listing = listings[i];
    const script = CHAT_SCRIPTS[i % CHAT_SCRIPTS.length];

    // Find a buyer (anyone who is NOT the seller)
    const buyer = users.find(u => u.uid !== listing.sellerId);
    if (!buyer) {
      console.warn(`   ⚠️  Skipping "${listing.title}" — no buyer found.`);
      skipped++;
      continue;
    }

    // Build chat ID (same algorithm as the Flutter app)
    const pair = [buyer.uid, listing.sellerId].sort();
    const chatId = `${pair[0]}_${pair[1]}_${listing.id}`;

    // Generate messages from the script
    const messages = script.buyerMsg(listing.title, listing.price);
    const lastMsg = messages[messages.length - 1];
    const lastSenderId = lastMsg.from === 'buyer' ? buyer.uid : listing.sellerId;
    const lastSenderName = lastMsg.from === 'buyer' ? buyer.name : listing.sellerName;

    // Check if chat already exists
    const existingChat = await db.collection('chats').doc(chatId).get();
    if (existingChat.exists) {
      console.log(`   ⏭️  Chat for "${listing.title}" already exists, skipping.`);
      skipped++;
      continue;
    }

    // Write chat document
    await db.collection('chats').doc(chatId).set({
      chatId,
      listingId: listing.id,
      listingTitle: listing.title,
      listingImage: listing.imageUrl,
      participants: [buyer.uid, listing.sellerId],
      buyerId: buyer.uid,
      sellerId: listing.sellerId,
      lastMessage: lastMsg.text,
      lastMessageAt: minutesAgo(1),
      createdAt: minutesAgo(messages.length * 5 + 30),
    });

    // Write all messages in a batch
    const batch = db.batch();
    messages.forEach((msg, idx) => {
      const senderId = msg.from === 'buyer' ? buyer.uid : listing.sellerId;
      const senderName = msg.from === 'buyer' ? buyer.name : listing.sellerName;
      const msgRef = db.collection('chats').doc(chatId).collection('messages').doc();

      batch.set(msgRef, {
        messageId: msgRef.id,
        senderId,
        senderName,
        text: msg.text,
        createdAt: minutesAgo((messages.length - idx) * 5),
      });
      messagesCreated++;
    });

    await batch.commit();

    const emoji = script.scenario.startsWith('safe') ? '🟢' :
                  script.scenario.startsWith('warning') ? '🟡' : '🔴';
    console.log(`   ${emoji} "${listing.title}" — ${buyer.name} ↔ ${listing.sellerName} (${messages.length} messages) [${script.scenario}]`);
    chatsCreated++;
  }

  // ── Done ──────────────────────────────────────────────────────────
  console.log('\n══════════════════════════════════════════════════════');
  console.log(`🎉 Done!`);
  console.log(`   ✅ ${chatsCreated} chat(s) created with ${messagesCreated} messages`);
  if (skipped > 0) console.log(`   ⏭️  ${skipped} skipped (already exist or no buyer)`);
  console.log('');
  console.log('📱 Open the app → Chat icon → see all conversations!');
  console.log('🛡️  Try AI Safety Scan on each chat to see different results:');
  console.log('   🟢 Safe — normal meetup conversations');
  console.log('   🟡 Warning — off-platform contact requests');
  console.log('   🔴 Danger — advance payment/deposit scam patterns');
  console.log('══════════════════════════════════════════════════════\n');
  process.exit(0);
}

seedChats().catch(err => {
  console.error('\n💥 Fatal error:', err.message || err);
  process.exit(1);
});

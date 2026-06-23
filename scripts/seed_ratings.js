/**
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║         CAMPUS MARKETPLACE — DEMO RATINGS SEED SCRIPT                  ║
 * ║  Seeds realistic seller ratings & reviews for the AI Reputation         ║
 * ║  Summary feature demo.                                                  ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 *
 * HOW TO RUN (from the scripts/ folder):
 *   node seed_ratings.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Re-use existing app or init a new one
try {
  admin.app();
} catch (e) {
  const serviceAccount = require(path.join(__dirname, '..', 'campusmarketplace-19060-firebase-adminsdk-fbsvc-6de09fb56b.json'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'campusmarketplace-19060',
  });
}

const db = admin.firestore();

// ─────────────────────────────────────────────────────────────────
// RATING TEMPLATES
// High-score (4-5 stars) and low-score (1-3) review texts
// ─────────────────────────────────────────────────────────────────
const POSITIVE_REVIEWS = [
  'Super smooth transaction! Item was exactly as described. Will buy again.',
  'Seller was very responsive and we met at KTDI on time. Highly recommend!',
  'Great deal, item in perfect condition. Friendly seller too!',
  'Fast reply and honest description. The item is exactly what I needed.',
  'Best seller I\'ve dealt with on campus. Item even better than the photos!',
  'Very trustworthy. Met at the agreed time and place, no issues at all.',
  'Quick response and great item quality. 5 stars without hesitation!',
  'Item arrived in excellent condition. Seller was polite and helpful.',
];

const MIXED_REVIEWS = [
  'Item was okay, condition was slightly worse than described but acceptable.',
  'Transaction was fine overall, just took a bit longer to arrange meetup.',
  'Decent seller. Communication was slow but item was as listed.',
  'Good item, price fair. Seller could communicate faster next time.',
];

const NEGATIVE_REVIEWS = [
  'Item condition was not as described. Some damage not shown in photos.',
  'Seller was late to the meetup and hard to reach. Very disappointing.',
  'Not what I expected based on the listing. Would caution other buyers.',
];

function pickRandom(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function daysAgo(n) {
  return admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - n * 24 * 60 * 60 * 1000)
  );
}

function getReviewForScore(score) {
  if (score >= 4) return pickRandom(POSITIVE_REVIEWS);
  if (score === 3) return pickRandom(MIXED_REVIEWS);
  return pickRandom(NEGATIVE_REVIEWS);
}

// ─────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────
async function seedRatings() {
  console.log('\n⭐ Campus Marketplace — Rating Seeder\n');
  console.log('📡 Fetching users and listings...\n');

  // Fetch users
  const usersSnap = await db.collection('users').get();
  const users = usersSnap.docs.map(doc => ({
    uid: doc.id,
    name: doc.data().name || 'Student',
    averageRating: doc.data().averageRating || 0,
    totalRatings: doc.data().totalRatings || 0,
  }));

  if (users.length < 2) {
    console.error('❌ Need at least 2 users. Register more accounts first.\n');
    process.exit(1);
  }

  console.log(`✅ Found ${users.length} users`);

  // Fetch listings to associate ratings with (optional, we use a fake requestId)
  const listingsSnap = await db.collection('listings').limit(20).get();
  const listings = listingsSnap.docs.map(d => ({ id: d.id, sellerId: d.data().sellerId }));

  let ratingsCreated = 0;
  let skipped = 0;

  // For each seller, create 3-6 reviews from random buyers
  for (const seller of users) {
    // Pick a reviewer pool (everyone except the seller)
    const reviewers = users.filter(u => u.uid !== seller.uid);
    if (reviewers.length === 0) continue;

    // Create between 3 and 5 ratings per seller
    const numRatings = 3 + Math.floor(Math.random() * 3);
    
    // Build scores weighted toward positive (for a realistic demo)
    const scores = [];
    for (let i = 0; i < numRatings; i++) {
      const roll = Math.random();
      if (roll < 0.55) scores.push(5);
      else if (roll < 0.80) scores.push(4);
      else if (roll < 0.90) scores.push(3);
      else if (roll < 0.96) scores.push(2);
      else scores.push(1);
    }

    let runningTotal = seller.totalRatings;
    let runningSum = seller.averageRating * runningTotal;

    for (let i = 0; i < scores.length; i++) {
      const score = scores[i];
      const reviewer = reviewers[i % reviewers.length];
      const comment = getReviewForScore(score);
      
      // Use a fake requestId to avoid duplicate-check conflicts in the app rules
      // (Admin SDK bypasses rules, so this writes directly)
      const fakeRequestId = `demo_${seller.uid}_${i}_${Date.now()}`;
      const ratingId = `${seller.uid}_${reviewer.uid}_${i}`;

      // Check if this rating already exists
      const existing = await db.collection('ratings').doc(ratingId).get();
      if (existing.exists) {
        skipped++;
        continue;
      }

      await db.collection('ratings').doc(ratingId).set({
        ratingId,
        reviewerId: reviewer.uid,
        reviewerName: reviewer.name,
        sellerId: seller.uid,
        listingId: listings.length > 0 ? listings[i % listings.length].id : 'demo',
        requestId: fakeRequestId,
        score,
        comment,
        createdAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() - (numRatings - i) * 3 * 24 * 60 * 60 * 1000)
        ),
      });

      // Update running average
      runningTotal++;
      runningSum += score;
      ratingsCreated++;
    }

    // Update seller's averageRating and totalRatings
    if (ratingsCreated > 0 || skipped === 0) {
      const newAvg = runningSum / runningTotal;
      await db.collection('users').doc(seller.uid).set({
        averageRating: Math.round(newAvg * 10) / 10,
        totalRatings: runningTotal,
      }, { merge: true });

      console.log(`   ⭐ ${seller.name}: ${runningTotal} ratings, avg ${(runningSum / runningTotal).toFixed(1)}/5`);
    }
  }

  console.log('\n══════════════════════════════════════════════════════');
  console.log(`🎉 Done!`);
  console.log(`   ✅ ${ratingsCreated} rating(s) created`);
  if (skipped > 0) console.log(`   ⏭️  ${skipped} already existed`);
  console.log('');
  console.log('📱 Open any seller profile in the app to see:');
  console.log('   🤖 AI Reputation Summary (auto-generated from these reviews)');
  console.log('   ⭐ Star rating & review cards');
  console.log('══════════════════════════════════════════════════════\n');
  process.exit(0);
}

seedRatings().catch(err => {
  console.error('\n💥 Fatal error:', err.message || err);
  process.exit(1);
});

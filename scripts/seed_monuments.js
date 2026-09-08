/**
 * seed_monuments.js
 * 
 * Injects both 'monuments' and linked 'pois' into Firestore following
 * the exact schema from your Firestore collections.
 * 
 * Usage:
 *   node scripts/seed_monuments.js [path/to/serviceAccountKey.json]
 *   Or with environment variable:
 *   FIREBASE_SERVICE_ACCOUNT_JSON='{...}' node scripts/seed_monuments.js
 */

const fs = require('fs');
const admin = require('firebase-admin');

// 1. Initialize Firebase Admin
let credential;
const serviceAccountPath = process.argv[2] || process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  const jsonStr = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  credential = admin.credential.cert(JSON.parse(jsonStr));
} else if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
  const accountJson = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  credential = admin.credential.cert(accountJson);
} else {
  credential = admin.credential.applicationDefault();
}

admin.initializeApp({
  credential,
  projectId: 'dishavaani-db373',
});

const db = admin.firestore();

const SUPABASE_BASE = 'https://fexglgxcvqcjjzsnhwrp.supabase.co/storage/v1/object/public/Audio';

// 2. Monuments Dataset
const MONUMENTS = {
  haveli_dharampura: {
    name: "Haveli Dharampura",
    description: "A restored 150-year-old haveli in Old Delhi offering cultural performances, heritage dining, and traditional Mughal architectural courtyards.",
    lat: 28.6562,
    long: 77.2310,
    categories: ["architecture", "history", "food"],
    siteType: "private",
    ownerContact: "Mr. Vijay Goel — contact@havelidharampura.com",
  },
  neemrana_fort: {
    name: "Neemrana Fort Palace",
    description: "A 15th-century heritage palace fort built on the Aravalli hills in Rajasthan, renowned for Rajput military architecture and tiered royal courtyards.",
    lat: 27.9942,
    long: 76.3869,
    categories: ["history", "military", "architecture"],
    siteType: "private",
    ownerContact: "Neemrana Hotels — reservations@neemranahotels.com",
  },
  qutub_minar: {
    name: "Qutub Minar",
    description: "A UNESCO World Heritage Site in Mehrauli, Delhi, featuring a 73-meter minaret and historic monuments dating back to the Delhi Sultanate.",
    lat: 28.5245,
    long: 77.1855,
    categories: ["history", "architecture", "religion"],
    siteType: "government",
    ownerContact: null,
  },
  red_fort: {
    name: "Red Fort",
    description: "Historic Mughal fortification in Old Delhi built by Emperor Shah Jahan in 1638, constructed of red sandstone with imperial audience halls.",
    lat: 28.6562,
    long: 77.2410,
    categories: ["history", "architecture", "politics"],
    siteType: "government",
    ownerContact: null,
  },
  humayuns_tomb: {
    name: "Humayun's Tomb",
    description: "The first garden-tomb on the Indian subcontinent, built in 1570, inspiring the Taj Mahal with Persian and Mughal synthesis.",
    lat: 28.5933,
    long: 77.2507,
    categories: ["history", "architecture", "culture"],
    siteType: "government",
    ownerContact: null,
  },
  jama_masjid: {
    name: "Jama Masjid",
    description: "One of the largest mosques in India, built by Mughal Emperor Shah Jahan between 1650 and 1656 in Old Delhi near Chandni Chowk.",
    lat: 28.6507,
    long: 77.2334,
    categories: ["architecture", "history", "religion"],
    siteType: "government",
    ownerContact: null,
  },
  agrashan_ki_baoli: {
    name: "Agrasen ki Baoli",
    description: "A 60-meter long and 15-meter wide historical step well on Hailey Road near Connaught Place, featuring 108 stone steps and arched recesses.",
    lat: 28.6258,
    long: 77.2250,
    categories: ["architecture", "history", "relaxation"],
    siteType: "government",
    ownerContact: null,
  },
  india_gate: {
    name: "India Gate",
    description: "A war memorial located along the Rajpath in New Delhi, dedicated to British Indian soldiers who died in the First World War.",
    lat: 28.6129,
    long: 77.2295,
    categories: ["history", "military", "culture"],
    siteType: "government",
    ownerContact: null,
  },
};

// 3. Linked POIs Dataset
const POIS = {
  // Haveli Dharampura
  haveli_dharampura_courtyard: {
    monumentId: "haveli_dharampura",
    name: "Central Courtyard",
    lat: 28.6562,
    long: 77.2310,
    bearingTolerance: 30,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/haveli_dharampura_courtyard_en.mp3`,
    },
    scripts: {
      en: "Welcome to the central courtyard of Haveli Dharampura. Notice the delicate brackets, carved sandstone pillars, and traditional jharokhas that allowed royal women to observe courtyard celebrations.",
    },
  },
  haveli_dharampura_rooftop: {
    monumentId: "haveli_dharampura",
    name: "Rooftop Heritage Terrace",
    lat: 28.6563,
    long: 77.2311,
    bearingTolerance: 30,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/haveli_dharampura_rooftop_en.mp3`,
    },
    scripts: {
      en: "From this rooftop vantage point, look across the historic skyline of Old Delhi. You can see the grand domes of Jama Masjid rising above the historic streets of Chandni Chowk.",
    },
  },

  // Neemrana Fort
  neemrana_fort_main_gate: {
    monumentId: "neemrana_fort",
    name: "Main Entrance Gate",
    lat: 27.9942,
    long: 76.3869,
    bearingTolerance: 30,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/neemrana_fort_main_gate_en.mp3`,
    },
    scripts: {
      en: "You are standing at the main entrance of Neemrana Fort Palace, built in 1464 by Maharaja Rajdeo. The massive gates you see were designed to withstand elephant charges — notice the heavy iron spikes studding the wooden doors.",
    },
  },
  neemrana_fort_stepwell: {
    monumentId: "neemrana_fort",
    name: "Neemrana Baoli (Stepwell)",
    lat: 27.9928,
    long: 76.3882,
    bearingTolerance: 35,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/neemrana_fort_stepwell_en.mp3`,
    },
    scripts: {
      en: "This multi-tiered subterranean stepwell descends nine stories underground, constructed in the 18th century to provide water security and cool subterranean respite for desert travelers.",
    },
  },

  // Qutub Minar
  qutub_minar_tower: {
    monumentId: "qutub_minar",
    name: "The Victory Tower (Qutub Minar)",
    lat: 28.5245,
    long: 77.1855,
    bearingTolerance: 25,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/qutub_minar_tower_en.mp3`,
    },
    scripts: {
      en: "Standing at 72.5 meters, Qutub Minar is the tallest brick minaret in the world, commenced by Qutb-ud-din Aibak in 1192 and featuring intricate balconies and fluted sandstone carvings.",
    },
  },
  qutub_minar_iron_pillar: {
    monumentId: "qutub_minar",
    name: "Ancient Iron Pillar",
    lat: 28.5247,
    long: 77.1853,
    bearingTolerance: 25,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/qutub_minar_iron_pillar_en.mp3`,
    },
    scripts: {
      en: "This 1,600-year-old iron pillar from the Gupta Empire is renowned for its metallurgical mystery—it has stood in the open air for centuries without rusting, testifying to ancient Indian mastery of iron casting.",
    },
  },
  qutub_minar_alai_darwaza: {
    monumentId: "qutub_minar",
    name: "Alai Darwaza Entrance",
    lat: 28.5240,
    long: 77.1858,
    bearingTolerance: 30,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/qutub_minar_alai_darwaza_en.mp3`,
    },
    scripts: {
      en: "Finally, this is the main entrance gate, built in 1311. It was the very first building in India built with a true dome and smooth, curved arches, contrasting white marble against red sandstone.",
    },
  },

  // Red Fort
  red_fort_lahori_gate: {
    monumentId: "red_fort",
    name: "Lahori Gate",
    lat: 28.6562,
    long: 77.2410,
    bearingTolerance: 30,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/red_fort_lahori_gate_en.mp3`,
    },
    scripts: {
      en: "Lahori Gate is the principal entrance to the Red Fort, named because it faces west toward the city of Lahore. The Indian Prime Minister hoists the national flag here every Independence Day.",
    },
  },
  red_fort_diwan_i_aam: {
    monumentId: "red_fort",
    name: "Diwan-i-Aam (Hall of Public Audience)",
    lat: 28.6564,
    long: 77.2422,
    bearingTolerance: 30,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/red_fort_diwan_i_aam_en.mp3`,
    },
    scripts: {
      en: "This colonnaded red sandstone hall was where Emperor Shah Jahan received his subjects and reviewed administrative affairs from an ornate, marble-canopied royal alcove.",
    },
  },

  // Humayun's Tomb
  humayuns_tomb_charbagh: {
    monumentId: "humayuns_tomb",
    name: "Central Charbagh Garden & Dome",
    lat: 28.5933,
    long: 77.2507,
    bearingTolerance: 25,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/humayuns_tomb_charbagh_en.mp3`,
    },
    scripts: {
      en: "The tomb stands at the heart of a Persian-style quadrilateral Charbagh garden divided into four parts by flowing water channels, symbolizing the paradise gardens of Mughal architectural poetry.",
    },
  },

  // Jama Masjid
  jama_masjid_courtyard: {
    monumentId: "jama_masjid",
    name: "Grand Courtyard & Prayer Hall",
    lat: 28.6507,
    long: 77.2334,
    bearingTolerance: 30,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/jama_masjid_courtyard_en.mp3`,
    },
    scripts: {
      en: "This expansive courtyard can accommodate over 25,000 worshippers, flanked by two 40-meter minarets constructed of alternating vertical strips of red sandstone and white marble.",
    },
  },

  // Agrasen ki Baoli
  agrashan_ki_baoli_stepwell: {
    monumentId: "agrashan_ki_baoli",
    name: "Main Stepped Reservoir",
    lat: 28.6258,
    long: 77.2250,
    bearingTolerance: 30,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/agrashan_ki_baoli_stepwell_en.mp3`,
    },
    scripts: {
      en: "Look down the dramatic flight of 108 stone steps flanked by three levels of arched niches. This 14th-century architectural gem was engineered for rainwater conservation and social gathering.",
    },
  },

  // India Gate
  india_gate_memorial: {
    monumentId: "india_gate",
    name: "Amar Jawan Jyoti Memorial Arch",
    lat: 28.6129,
    long: 77.2295,
    bearingTolerance: 30,
    audioUrls: {
      en: `${SUPABASE_BASE}/tts_cached/india_gate_memorial_en.mp3`,
    },
    scripts: {
      en: "Designed by Sir Edwin Lutyens, this 42-meter triumphal arch commemorates 84,000 soldiers. Inscribed upon its walls are the names of over 13,000 servicemen who died during the First World War.",
    },
  },
};

async function seedDatabase() {
  console.log("🌱 Starting Firestore seed...");
  const batch = db.batch();

  // 1. Monuments
  for (const [id, data] of Object.entries(MONUMENTS)) {
    const docRef = db.collection("monuments").doc(id);
    batch.set(docRef, data, { merge: true });
    console.log(`  🏛️  Prepared monument: ${id} (${data.name})`);
  }

  // 2. Linked POIs
  for (const [id, data] of Object.entries(POIS)) {
    const docRef = db.collection("pois").doc(id);
    batch.set(docRef, data, { merge: true });
    console.log(`  📍 Prepared POI: ${id} -> linked to [${data.monumentId}]`);
  }

  await batch.commit();
  console.log(`\n✅ Success! Seeded:`);
  console.log(`   - ${Object.keys(MONUMENTS).length} monuments into 'monuments'`);
  console.log(`   - ${Object.keys(POIS).length} linked POIs into 'pois'`);
}

seedDatabase()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("❌ Seeding failed:", err);
    process.exit(1);
  });

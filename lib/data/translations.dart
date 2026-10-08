// Import the flutter_riverpod package to use its state management features.
// Riverpod helps us manage and listen to changes in our app's data.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import our custom app_state.dart file which contains the language preference provider.
// This allows us to know which language the user has currently selected.
import '../providers/app_state.dart';

// Define a constant private Map (dictionary) named '_dict'.
// The 'const' keyword means this data is fixed at compile-time and cannot be changed.
// It maps language codes (like 'hi' for Hindi) to another Map of English strings and their translated strings.
const Map<String, Map<String, String>> _dict = {
  // 'hi' stands for Hindi. This section contains English to Hindi translations.
  'hi': {
    // English 'Settings' translates to Hindi 'सेटिंग्स'
    'Settings': 'सेटिंग्स',
    // English 'Appearance' translates to Hindi 'दिखावट'
    'Appearance': 'दिखावट',
    // English 'Theme' translates to Hindi 'थीम'
    'Theme': 'थीम',
    // English 'Dark' translates to Hindi 'गहरा'
    'Dark': 'गहरा',
    // English 'Light' translates to Hindi 'हल्का'
    'Light': 'हल्का',
    // English 'Your account' translates to Hindi 'आपका खाता'
    'Your account': 'आपका खाता',
    // English 'Your ID' translates to Hindi 'आपकी आईडी'
    'Your ID': 'आपकी आईडी',
    // English 'PIN & biometrics' translates to Hindi 'पिन और बायोमेट्रिक्स'
    'PIN & biometrics': 'पिन और बायोमेट्रिक्स',
    // English 'Configured' translates to Hindi 'कॉन्फ़िगर किया गया'
    'Configured': 'कॉन्फ़िगर किया गया',
    // English 'Language & region' translates to Hindi 'भाषा और क्षेत्र'
    'Language & region': 'भाषा और क्षेत्र',
    // English 'Language' translates to Hindi 'भाषा'
    'Language': 'भाषा',
    // English 'Notifications' translates to Hindi 'सूचनाएं'
    'Notifications': 'सूचनाएं',
    // English 'Daily reminder' translates to Hindi 'दैनिक अनुस्मारक'
    'Daily reminder': 'दैनिक अनुस्मारक',
    // English 'Sync alerts' translates to Hindi 'सिंक अलर्ट'
    'Sync alerts': 'सिंक अलर्ट',
    // English 'Weekly summary' translates to Hindi 'साप्ताहिक सारांश'
    'Weekly summary': 'साप्ताहिक सारांश',
    // English 'Data & privacy' translates to Hindi 'डेटा और गोपनीयता'
    'Data & privacy': 'डेटा और गोपनीयता',
    // English 'Data handling' translates to Hindi 'डेटा प्रबंधन'
    'Data handling': 'डेटा प्रबंधन',
    // English 'Delete all my data' translates to Hindi 'मेरा सारा डेटा हटाएं'
    'Delete all my data': 'मेरा सारा डेटा हटाएं',
    // English 'Session' translates to Hindi 'सत्र'
    'Session': 'सत्र',
    // English 'Sign out' translates to Hindi 'साइन आउट'
    'Sign out': 'साइन आउट',
    // English 'Device' translates to Hindi 'उपकरण'
    'Device': 'उपकरण',
    // English 'Deactivate this device' translates to Hindi 'इस उपकरण को निष्क्रिय करें'
    'Deactivate this device': 'इस उपकरण को निष्क्रिय करें',
    // English 'About' translates to Hindi 'के बारे में'
    'About': 'के बारे में',
    // English 'App version' translates to Hindi 'ऐप संस्करण'
    'App version': 'ऐप संस्करण',
    // English 'Unit programme' translates to Hindi 'यूनिट कार्यक्रम'
    'Unit programme': 'यूनिट कार्यक्रम',
    // English 'Cancel' translates to Hindi 'रद्द करें'
    'Cancel': 'रद्द करें',
    // English 'Delete Data' translates to Hindi 'डेटा हटाएं'
    'Delete Data': 'डेटा हटाएं',
    // English 'Deactivate' translates to Hindi 'निष्क्रिय करें'
    'Deactivate': 'निष्क्रिय करें',
    // English 'Home' translates to Hindi 'होम'
    'Home': 'होम',
    // English 'Trend' translates to Hindi 'ट्रेंड'
    'Trend': 'ट्रेंड',
    // English 'Support' translates to Hindi 'सहायता'
    'Support': 'सहायता',
    // English 'Good morning' translates to Hindi 'शुभ प्रभात'
    'Good morning': 'शुभ प्रभात',
    // English 'Good afternoon' translates to Hindi 'शुभ दोपहर'
    'Good afternoon': 'शुभ दोपहर',
    // English 'Good evening' translates to Hindi 'शुभ संध्या'
    'Good evening': 'शुभ संध्या',
    // English 'Day' translates to Hindi 'दिन'
    'Day': 'दिन',
    // English 'Checked in today' translates to Hindi 'आज चेक-इन किया'
    'Checked in today': 'आज चेक-इन किया',
    // English 'Not yet checked in today' translates to Hindi 'आज अभी चेक-इन नहीं किया'
    'Not yet checked in today': 'आज अभी चेक-इन नहीं किया',
    // English "View today's entry" translates to Hindi 'आज की प्रविष्टि देखें'
    "View today's entry": 'आज की प्रविष्टि देखें',
    // English "Start today's check-in" translates to Hindi 'आज का चेक-इन शुरू करें'
    "Start today's check-in": 'आज का चेक-इन शुरू करें',
    // English 'View my trend' translates to Hindi 'मेरा ट्रेंड देखें'
    'View my trend': 'मेरा ट्रेंड देखें',
    // English 'Resources & support' translates to Hindi 'संसाधन और सहायता'
    'Resources & support': 'संसाधन और सहायता',
    // English 'My trend' translates to Hindi 'मेरा ट्रेंड'
    'My trend': 'मेरा ट्रेंड',
    // English 'Last 7 entries' translates to Hindi 'पिछले 7 प्रविष्टियां'
    'Last 7 entries': 'पिछले 7 प्रविष्टियां',
    // English 'Visible only to you' translates to Hindi 'केवल आपको दिखाई देता है'
    'Visible only to you': 'केवल आपको दिखाई देता है',
    // English '30-DAY OVERVIEW' translates to Hindi '30-दिन का अवलोकन'
    '30-DAY OVERVIEW': '30-दिन का अवलोकन',
    // English '7-day average' translates to Hindi '7-दिन का औसत'
    '7-day average': '7-दिन का औसत',
    // English 'UPCOMING CALENDAR' translates to Hindi 'आगामी कैलेंडर'
    'UPCOMING CALENDAR': 'आगामी कैलेंडर',
    // English 'SUGGESTED FOR YOU' translates to Hindi 'आपके लिए सुझाया गया'
    'SUGGESTED FOR YOU': 'आपके लिए सुझाया गया',
    // English 'BIOMETRICS (SIMULATED)' translates to Hindi 'बायोमेट्रिक्स'
    'BIOMETRICS (SIMULATED)': 'बायोमेट्रिक्स',
    // English 'Daily readiness check-in' translates to Hindi 'दैनिक तत्परता चेक-इन'
    'Daily readiness check-in': 'दैनिक तत्परता चेक-इन',
    // English 'Private to you and your unit lead. Takes about a minute.' translates to Hindi 'आपके और यूनिट लीड के लिए निजी। लगभग 1 मिनट लगता है।'
    'Private to you and your unit lead. Takes about a minute.': 'आपके और यूनिट लीड के लिए निजी। लगभग 1 मिनट लगता है।',
    // English 'Anything to add? ' translates to Hindi 'कुछ और जोड़ना है? '
    'Anything to add? ': 'कुछ और जोड़ना है? ',
    // English '(optional)' translates to Hindi '(वैकल्पिक)'
    '(optional)': '(वैकल्पिक)',
    // English 'Brief note for your record...' translates to Hindi 'आपके रिकॉर्ड के लिए संक्षिप्त नोट...'
    'Brief note for your record...': 'आपके रिकॉर्ड के लिए संक्षिप्त नोट...',
    // English "Log today's readiness" translates to Hindi 'आज की तत्परता दर्ज करें'
    "Log today's readiness": 'आज की तत्परता दर्ज करें',
    // English 'complete' translates to Hindi 'पूरा हुआ'
    'complete': 'पूरा हुआ',
    // English 'Readiness logged' translates to Hindi 'तत्परता दर्ज की गई'
    'Readiness logged': 'तत्परता दर्ज की गई',
    // English 'Back to home' translates to Hindi 'होम पर वापस जाएं'
    'Back to home': 'होम पर वापस जाएं',
  },
  // 'mr' stands for Marathi. This section contains English to Marathi translations.
  'mr': {
    // English 'Settings' translates to Marathi 'सेटिंग्ज'
    'Settings': 'सेटिंग्ज',
    // English 'Appearance' translates to Marathi 'स्वरूप'
    'Appearance': 'स्वरूप',
    // English 'Theme' translates to Marathi 'थीम'
    'Theme': 'थीम',
    // English 'Dark' translates to Marathi 'गडद'
    'Dark': 'गडद',
    // English 'Light' translates to Marathi 'फिकट'
    'Light': 'फिकट',
    // English 'Your account' translates to Marathi 'तुमचे खाते'
    'Your account': 'तुमचे खाते',
    // English 'Your ID' translates to Marathi 'तुमचा आयडी'
    'Your ID': 'तुमचा आयडी',
    // English 'PIN & biometrics' translates to Marathi 'पिन आणि बायोमेट्रिक्स'
    'PIN & biometrics': 'पिन आणि बायोमेट्रिक्स',
    // English 'Configured' translates to Marathi 'कॉन्फिगर केले'
    'Configured': 'कॉन्फिगर केले',
    // English 'Language & region' translates to Marathi 'भाषा आणि प्रदेश'
    'Language & region': 'भाषा आणि प्रदेश',
    // English 'Language' translates to Marathi 'भाषा'
    'Language': 'भाषा',
    // English 'Notifications' translates to Marathi 'सूचना'
    'Notifications': 'सूचना',
    // English 'Daily reminder' translates to Marathi 'दैनिक स्मरणपत्र'
    'Daily reminder': 'दैनिक स्मरणपत्र',
    // English 'Sync alerts' translates to Marathi 'सिंक सूचना'
    'Sync alerts': 'सिंक सूचना',
    // English 'Weekly summary' translates to Marathi 'साप्ताहिक सारांश'
    'Weekly summary': 'साप्ताहिक सारांश',
    // English 'Data & privacy' translates to Marathi 'डेटा आणि गोपनीयता'
    'Data & privacy': 'डेटा आणि गोपनीयता',
    // English 'Data handling' translates to Marathi 'डेटा हाताळणी'
    'Data handling': 'डेटा हाताळणी',
    // English 'Delete all my data' translates to Marathi 'माझा सर्व डेटा हटवा'
    'Delete all my data': 'माझा सर्व डेटा हटवा',
    // English 'Session' translates to Marathi 'सत्र'
    'Session': 'सत्र',
    // English 'Sign out' translates to Marathi 'साइन आउट करा'
    'Sign out': 'साइन आउट करा',
    // English 'Device' translates to Marathi 'डिव्हाइस'
    'Device': 'डिव्हाइस',
    // English 'Deactivate this device' translates to Marathi 'हे डिव्हाइस निष्क्रिय करा'
    'Deactivate this device': 'हे डिव्हाइस निष्क्रिय करा',
    // English 'About' translates to Marathi 'विषयी'
    'About': 'विषयी',
    // English 'Home' translates to Marathi 'होम'
    'Home': 'होम',
    // English 'Trend' translates to Marathi 'ट्रेंड'
    'Trend': 'ट्रेंड',
    // English 'Support' translates to Marathi 'सपोर्ट'
    'Support': 'सपोर्ट',
    // English 'Good morning' translates to Marathi 'शुभ प्रभात'
    'Good morning': 'शुभ प्रभात',
    // English 'Good afternoon' translates to Marathi 'शुभ दुपार'
    'Good afternoon': 'शुभ दुपार',
    // English 'Good evening' translates to Marathi 'शुभ संध्याकाळ'
    'Good evening': 'शुभ संध्याकाळ',
    // English 'Checked in today' translates to Marathi 'आज चेक-इन केले'
    'Checked in today': 'आज चेक-इन केले',
    // English 'Not yet checked in today' translates to Marathi 'आज अजून चेक-इन केले नाही'
    'Not yet checked in today': 'आज अजून चेक-इन केले नाही',
    // English "Start today's check-in" translates to Marathi 'आजचे चेक-इन सुरू करा'
    "Start today's check-in": 'आजचे चेक-इन सुरू करा',
    // English "View today's entry" translates to Marathi 'आजची नोंद पहा'
    "View today's entry": 'आजची नोंद पहा',
    // English 'View my trend' translates to Marathi 'माझा ट्रेंड पहा'
    'View my trend': 'माझा ट्रेंड पहा',
    // English 'Resources & support' translates to Marathi 'संसाधने आणि समर्थन'
    'Resources & support': 'संसाधने आणि समर्थन',
    // English 'My trend' translates to Marathi 'माझा ट्रेंड'
    'My trend': 'माझा ट्रेंड',
    // English 'Daily readiness check-in' translates to Marathi 'दैनिक तयारी चेक-इन'
    'Daily readiness check-in': 'दैनिक तयारी चेक-इन',
    // English "Log today's readiness" translates to Marathi 'आजची तयारी नोंदवा'
    "Log today's readiness": 'आजची तयारी नोंदवा',
    // English 'Readiness logged' translates to Marathi 'तयारी नोंदवली'
    'Readiness logged': 'तयारी नोंदवली',
    // English 'Back to home' translates to Marathi 'होमवर परत जा'
    'Back to home': 'होमवर परत जा',
  },
  // 'bn' stands for Bengali. This section contains English to Bengali translations.
  'bn': {
    // English 'Settings' translates to Bengali 'সেটিংস'
    'Settings': 'সেটিংস',
    // English 'Appearance' translates to Bengali 'চেহারা'
    'Appearance': 'চেহারা',
    // English 'Theme' translates to Bengali 'থিম'
    'Theme': 'থিম',
    // English 'Dark' translates to Bengali 'অন্ধকার'
    'Dark': 'অন্ধকার',
    // English 'Light' translates to Bengali 'হালকা'
    'Light': 'হালকা',
    // English 'Your account' translates to Bengali 'আপনার অ্যাকাউন্ট'
    'Your account': 'আপনার অ্যাকাউন্ট',
    // English 'Your ID' translates to Bengali 'আপনার আইডি'
    'Your ID': 'আপনার আইডি',
    // English 'PIN & biometrics' translates to Bengali 'পিন এবং বায়োমেট্রিক্স'
    'PIN & biometrics': 'পিন এবং বায়োমেট্রিক্স',
    // English 'Configured' translates to Bengali 'কনফিগার করা হয়েছে'
    'Configured': 'কনফিগার করা হয়েছে',
    // English 'Language & region' translates to Bengali 'ভাষা এবং অঞ্চল'
    'Language & region': 'ভাষা এবং অঞ্চল',
    // English 'Language' translates to Bengali 'ভাষা'
    'Language': 'ভাষা',
    // English 'Notifications' translates to Bengali 'বিজ্ঞপ্তি'
    'Notifications': 'বিজ্ঞপ্তি',
    // English 'Daily reminder' translates to Bengali 'দৈনিক অনুস্মারক'
    'Daily reminder': 'দৈনিক অনুস্মারক',
    // English 'Data & privacy' translates to Bengali 'ডেটা এবং গোপনীয়তা'
    'Data & privacy': 'ডেটা এবং গোপনীয়তা',
    // English 'Delete all my data' translates to Bengali 'আমার সমস্ত ডেটা মুছুন'
    'Delete all my data': 'আমার সমস্ত ডেটা মুছুন',
    // English 'Sign out' translates to Bengali 'সাইন আউট'
    'Sign out': 'সাইন আউট',
    // English 'Home' translates to Bengali 'হোম'
    'Home': 'হোম',
    // English 'Trend' translates to Bengali 'ট্রেন্ড'
    'Trend': 'ট্রেন্ড',
    // English 'Support' translates to Bengali 'সমর্থন'
    'Support': 'সমর্থন',
    // English 'Good morning' translates to Bengali 'সুপ্রভাত'
    'Good morning': 'সুপ্রভাত',
    // English 'Good afternoon' translates to Bengali 'শুভ অপরাহ্ন'
    'Good afternoon': 'শুভ অপরাহ্ন',
    // English 'Good evening' translates to Bengali 'শুভ সন্ধ্যা'
    'Good evening': 'শুভ সন্ধ্যা',
  },
  // 'te' stands for Telugu. This section contains English to Telugu translations.
  'te': {
    // English 'Settings' translates to Telugu 'సెట్టింగ్‌లు'
    'Settings': 'సెట్టింగ్‌లు',
    // English 'Appearance' translates to Telugu 'కనిపించు విధానం'
    'Appearance': 'కనిపించు విధానం',
    // English 'Theme' translates to Telugu 'థీమ్'
    'Theme': 'థీమ్',
    // English 'Dark' translates to Telugu 'చీకటి'
    'Dark': 'చీకటి',
    // English 'Light' translates to Telugu 'వెలుగు'
    'Light': 'వెలుగు',
    // English 'Your account' translates to Telugu 'మీ ఖాతా'
    'Your account': 'మీ ఖాతా',
    // English 'Language & region' translates to Telugu 'భాష మరియు ప్రాంతం'
    'Language & region': 'భాష మరియు ప్రాంతం',
    // English 'Language' translates to Telugu 'భాష'
    'Language': 'భాష',
    // English 'Notifications' translates to Telugu 'నోటిఫికేషన్‌లు'
    'Notifications': 'నోటిఫికేషన్‌లు',
    // English 'Sign out' translates to Telugu 'సైన్ అవుట్'
    'Sign out': 'సైన్ అవుట్',
    // English 'Home' translates to Telugu 'హోమ్'
    'Home': 'హోమ్',
    // English 'Trend' translates to Telugu 'ట్రెండ్'
    'Trend': 'ట్రెండ్',
    // English 'Support' translates to Telugu 'మద్దతు'
    'Support': 'మద్దతు',
    // English 'Good morning' translates to Telugu 'శుభోదయం'
    'Good morning': 'శుభోదయం',
    // English 'Good afternoon' translates to Telugu 'శుభ మధ్యాహ్నం'
    'Good afternoon': 'శుభ మధ్యాహ్నం',
    // English 'Good evening' translates to Telugu 'శుభ సాయంత్రం'
    'Good evening': 'శుభ సాయంత్రం',
  },
  // 'ta' stands for Tamil. This section contains English to Tamil translations.
  'ta': {
    // English 'Settings' translates to Tamil 'அமைப்புகள்'
    'Settings': 'அமைப்புகள்',
    // English 'Theme' translates to Tamil 'தீம்'
    'Theme': 'தீம்',
    // English 'Dark' translates to Tamil 'இருண்ட'
    'Dark': 'இருண்ட',
    // English 'Light' translates to Tamil 'ஒளி'
    'Light': 'ஒளி',
    // English 'Your account' translates to Tamil 'உங்கள் கணக்கு'
    'Your account': 'உங்கள் கணக்கு',
    // English 'Language' translates to Tamil 'மொழி'
    'Language': 'மொழி',
    // English 'Sign out' translates to Tamil 'வெளியேறு'
    'Sign out': 'வெளியேறு',
    // English 'Home' translates to Tamil 'முகப்பு'
    'Home': 'முகப்பு',
    // English 'Trend' translates to Tamil 'போக்கு'
    'Trend': 'போக்கு',
    // English 'Support' translates to Tamil 'ஆதரவு'
    'Support': 'ஆதரவு',
  },
  // 'gu' stands for Gujarati. This section contains English to Gujarati translations.
  'gu': {
    // English 'Settings' translates to Gujarati 'સેટિંગ્સ'
    'Settings': 'સેટિંગ્સ',
    // English 'Theme' translates to Gujarati 'થીમ'
    'Theme': 'થીમ',
    // English 'Dark' translates to Gujarati 'શ્યામ'
    'Dark': 'શ્યામ',
    // English 'Light' translates to Gujarati 'આછું'
    'Light': 'આછું',
    // English 'Your account' translates to Gujarati 'તમારું ખાતું'
    'Your account': 'તમારું ખાતું',
    // English 'Language' translates to Gujarati 'ભાષા'
    'Language': 'ભાષા',
    // English 'Sign out' translates to Gujarati 'સાઇન આઉટ'
    'Sign out': 'સાઇન આઉટ',
    // English 'Home' translates to Gujarati 'હોમ'
    'Home': 'હોમ',
    // English 'Trend' translates to Gujarati 'વલણ'
    'Trend': 'વલણ',
    // English 'Support' translates to Gujarati 'આધાર'
    'Support': 'આધાર',
  },
};

// Define a function named 'tr' (short for translate).
// It takes two parameters:
// 1. 'text': The original English String that we want to translate.
// 2. 'ref': A WidgetRef object from Riverpod to watch for the current language state.
String tr(String text, WidgetRef ref) {
  // Watch the 'languagePrefProvider' to get the current language code selected by the user.
  // Whenever the user changes the language, this function will rerun and update the UI automatically.
  final langCode = ref.watch(languagePrefProvider);
  
  // If the selected language code is 'en-GB' (British English) or 'en-US' (American English),
  // there is no need to translate, so we just return the original English text.
  if (langCode == 'en-GB' || langCode == 'en-US') return text;
  
  // Look up the translation dictionary for the selected language code (like 'hi', 'mr', etc.).
  // 'langDict' will contain the Map of translations for that specific language.
  final langDict = _dict[langCode];
  
  // If the language code is not found in our dictionary (e.g., it's a language we don't support yet),
  // 'langDict' will be null. In this case, we simply return the original English text as a fallback.
  if (langDict == null) return text;
  
  // If the dictionary exists for the language, we try to find the translation for the specific 'text'.
  // If the translation exists (e.g., 'Settings' maps to 'सेटिंग्स'), it returns that translated string.
  // If the translation does not exist in the dictionary, the '??' operator provides the original 'text' as a fallback.
  return langDict[text] ?? text;
}

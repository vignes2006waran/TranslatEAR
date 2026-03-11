import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

class TranslationService {
  static TranslationService? _instance;
  static TranslationService get instance => _instance ??= TranslationService._();
  TranslationService._();

  final _modelManager = OnDeviceTranslatorModelManager();
  final _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.3);
  final Map<String, OnDeviceTranslator> _translators = {};

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  TranslateLanguage _targetLang = TranslateLanguage.tamil;
  String _targetLangName = 'Tamil';
  TranslateLanguage get currentTargetLang => _targetLang;
  String get currentTargetLangName => _targetLangName;

  // ═══════════════════════════════════════════════════════════════════════════
  // ROMAN → NATIVE SCRIPT CONVERTERS
  // Each map has UNIQUE keys only — no duplicates allowed in Dart const maps.
  // Languages that share word spellings get separate maps with unique entries.
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Hindi: Roman → Devanagari ─────────────────────────────────────────────
  static const Map<String, String> _hindiMap = {
    'tumhara': 'तुम्हारा', 'tumhari': 'तुम्हारी', 'tumhe': 'तुम्हें',
    'mera': 'मेरा', 'meri': 'मेरी', 'mere': 'मेरे',
    'aapka': 'आपका', 'aapki': 'आपकी', 'aapke': 'आपके',
    'uska': 'उसका', 'uski': 'उसकी', 'unka': 'उनका', 'unki': 'उनकी',
    'naam': 'नाम', 'kya': 'क्या', 'hai': 'है', 'hain': 'हैं',
    'kaise': 'कैसे', 'kaisa': 'कैसा', 'kaisi': 'कैसी',
    'kahan': 'कहाँ', 'kyun': 'क्यों', 'kyunki': 'क्योंकि',
    'kab': 'कब', 'kitna': 'कितना', 'kitni': 'कितनी', 'kitne': 'कितने',
    'kaun': 'कौन', 'koi': 'कोई', 'kuch': 'कुछ',
    'main': 'मैं', 'mein': 'में', 'hum': 'हम', 'tum': 'तुम',
    'aap': 'आप', 'yeh': 'यह', 'woh': 'वह', 'wo': 'वो',
    'nahi': 'नहीं', 'nahin': 'नहीं',
    'aur': 'और', 'lekin': 'लेकिन', 'par': 'पर', 'bhi': 'भी',
    'sirf': 'सिर्फ', 'bahut': 'बहुत', 'thoda': 'थोड़ा', 'thodi': 'थोड़ी',
    'abhi': 'अभी', 'phir': 'फिर', 'sab': 'सब',
    'achha': 'अच्छा', 'theek': 'ठीक', 'sahi': 'सही', 'galat': 'गलत',
    'zyada': 'ज़्यादा', 'kam': 'कम',
    'khana': 'खाना', 'pani': 'पानी', 'ghar': 'घर', 'kaam': 'काम',
    'baat': 'बात', 'din': 'दिन', 'raat': 'रात', 'log': 'लोग',
    'dost': 'दोस्त', 'yaar': 'यार', 'bhai': 'भाई', 'behen': 'बहन',
    'mata': 'माता', 'pita': 'पिता', 'beta': 'बेटा', 'beti': 'बेटी',
    'jana': 'जाना', 'aana': 'आना', 'karna': 'करना', 'rehna': 'रहना',
    'dekhna': 'देखना', 'sunna': 'सुनना', 'bolna': 'बोलना',
    'tha': 'था', 'thi': 'थी',
    'hoga': 'होगा', 'hogi': 'होगी', 'honge': 'होंगे',
    'chahiye': 'चाहिए', 'sakta': 'सकता', 'sakti': 'सकती',
    'karo': 'करो', 'batao': 'बताओ', 'dekho': 'देखो',
    'suno': 'सुनो', 'chalo': 'चलो', 'ruko': 'रुको',
    'namaste': 'नमस्ते', 'shukriya': 'शुक्रिया', 'dhanyawad': 'धन्यवाद',
    'haan': 'हाँ', 'han': 'हाँ', 'ji': 'जी',
    'kal': 'कल', 'aaj': 'आज',
    'acchi': 'अच्छी', 'bura': 'बुरा', 'buri': 'बुरी',
    'dono': 'दोनों', 'sabhi': 'सभी', 'har': 'हर',
    'gaya': 'गया', 'gayi': 'गई', 'liya': 'लिया', 'diya': 'दिया',
    'hua': 'हुआ', 'hui': 'हुई', 'raha': 'रहा', 'rahi': 'रही', 'rahe': 'रहे',
    'apna': 'अपना', 'apni': 'अपनी', 'apne': 'अपने',
    'pura': 'पूरा', 'sach': 'सच',
    'pyaar': 'प्यार', 'mohabbat': 'मोहब्बत',
    'peena': 'पीना', 'sona': 'सोना', 'uthna': 'उठना',
    'baithna': 'बैठना', 'chalna': 'चलना', 'dena': 'देना', 'lena': 'लेना',
    'padhna': 'पढ़ना', 'likhna': 'लिखना', 'khelna': 'खेलना',
  };

  // ── Telugu: Roman → Telugu script ─────────────────────────────────────────
  static const Map<String, String> _teluguMap = {
    'nenu': 'నేను', 'meeru': 'మీరు', 'mee': 'మీ',
    'atanu': 'అతను', 'aaame': 'ఆమె', 'manam': 'మనం', 'memu': 'మేము',
    'vallaru': 'వాళ్ళు', 'vaadu': 'వాడు',
    'enti': 'ఏంటి', 'teela': 'ఎలా', 'evaru': 'ఎవరు', 'ekkada': 'ఎక్కడ',
    'enduku': 'ఎందుకు', 'eppudu': 'ఎప్పుడు', 'entha': 'ఎంత',
    'emiti': 'ఏమిటి',
    'unnaru': 'ఉన్నారు', 'unnav': 'ఉన్నావు',
    'teludu': 'తెలుదు', 'teundi': 'ఉంది', 'unte': 'ఉంటే',
    'chala': 'చాలా', 'konchem': 'కొంచెం',
    'nuvvu': 'నువ్వు', 'meeruperu': 'మీ పేరు', 'emaina': 'ఏమైనా',
    'cheyyandi': 'చెయ్యండి', 'vachindi': 'వచ్చింది', 'cheppandi': 'చెప్పండి',
    'chestanu': 'చేస్తాను', 'vastanu': 'వస్తాను', 'istanu': 'ఇస్తాను',
    'manchidi': 'మంచిది', 'cheddadi': 'చెడ్డది', 'pedda': 'పెద్ద',
    'chinna': 'చిన్న', 'kottadi': 'కొత్తది',
    'namaskaaram': 'నమస్కారం', 'dhanyavaadalu': 'ధన్యవాదాలు',
    'tesari': 'సరి', 'avunu': 'అవును', 'kaadu': 'కాదు',
    'ikkade': 'ఇక్కడే', 'akkade': 'అక్కడే',
    'tenanaa': 'నా', 'temaa': 'మా',
    'illu': 'ఇల్లు', 'teooru': 'ఊరు', 'tepani': 'పని',
    'tindi': 'తిండి', 'neellu': 'నీళ్ళు',
    'roju': 'రోజు', 'raatri': 'రాత్రి', 'neeru': 'నీరు',
    'ela': 'ఎలా', 'nee': 'నీ', 'peru': 'పేరు',
    'ledu': 'లేదు', 'undi': 'ఉంది',
  };

  // ── Kannada: Roman → Kannada script ───────────────────────────────────────
  static const Map<String, String> _kannadaMap = {
    'nanu': 'ನಾನು', 'neevu': 'ನೀವು', 'avanu': 'ಅವನು', 'avalu': 'ಅವಳು',
    'naavu': 'ನಾವು', 'nimma': 'ನಿಮ್ಮ', 'nanna': 'ನನ್ನ',
    'ivanu': 'ಇವನು', 'ivalu': 'ಇವಳು', 'addu': 'ಅದು',
    'enu': 'ಏನು', 'hege': 'ಹೇಗೆ', 'yaake': 'ಯಾಕೆ', 'yelli': 'ಎಲ್ಲಿ',
    'yaavaga': 'ಯಾವಾಗ', 'yeshtu': 'ಎಷ್ಟು', 'yaaru': 'ಯಾರು',
    'enidhu': 'ಏನಿದು',
    'knide': 'ಇದೆ', 'knilla': 'ಇಲ್ಲ', 'iddare': 'ಇದ್ದರೆ',
    'banni': 'ಬನ್ನಿ', 'knhogi': 'ಹೋಗಿ', 'madi': 'ಮಾಡಿ',
    'maduttene': 'ಮಾಡುತ್ತೇನೆ', 'baruttene': 'ಬರುತ್ತೇನೆ',
    'hoguttene': 'ಹೋಗುತ್ತೇನೆ', 'nodi': 'ನೋಡಿ', 'keli': 'ಕೇಳಿ',
    'heli': 'ಹೇಳಿ', 'tini': 'ತಿನ್ನಿ', 'kudi': 'ಕುಡಿ',
    'channagide': 'ಚೆನ್ನಾಗಿದೆ', 'channagi': 'ಚೆನ್ನಾಗಿ',
    'dodda': 'ದೊಡ್ಡ', 'chikka': 'ಚಿಕ್ಕ', 'hosa': 'ಹೊಸ',
    'namaskara': 'ನಮಸ್ಕಾರ', 'dhanyavada': 'ಧನ್ಯವಾದ',
    'knsari': 'ಸರಿ', 'howdu': 'ಹೌದು', 'knalla': 'ಅಲ್ಲ',
    'mane': 'ಮನೆ', 'kelasa': 'ಕೆಲಸ', 'neeru': 'ನೀರು', 'oota': 'ಊಟ',
    'dina': 'ದಿನ', 'raatri': 'ರಾತ್ರಿ', 'hesaru': 'ಹೆಸರು',
    'nimage': 'ನಿಮಗೆ', 'nanage': 'ನನಗೆ', 'knooru': 'ಊರು',
    'illa': 'ಇಲ್ಲ', 'ide': 'ಇದೆ', 'alla': 'ಅಲ್ಲ', 'sari': 'ಸರಿ',
    'hogi': 'ಹೋಗಿ', 'ooru': 'ಊರು',
  };

  // ── Tamil: Roman → Tamil script ────────────────────────────────────────────
  static const Map<String, String> _tamilMap = {
    'naan': 'நான்', 'neenga': 'நீங்கள்', 'avaan': 'அவன்',
    'avaal': 'அவள்', 'naanga': 'நாங்கள்', 'namma': 'நம்ம',
    'avan': 'அவன்', 'aval': 'அவள்', 'avanga': 'அவங்க',
    'enna': 'என்ன', 'eppo': 'எப்போ', 'enge': 'எங்கே',
    'eppadi': 'எப்படி', 'yen': 'ஏன்', 'tayaar': 'யார்',
    'evlo': 'எவ்வளவு', 'tentha': 'எந்த',
    'romba': 'ரொம்ப', 'konjam': 'கொஞ்சம்',
    'tailla': 'இல்ல', 'tailai': 'இல்லை',
    'iruku': 'இருக்கு', 'iruken': 'இருக்கேன்',
    'seri': 'சரி', 'vanakkam': 'வணக்கம்',
    'nandri': 'நன்றி', 'theriyum': 'தெரியும்', 'theriyala': 'தெரியல',
    'aamaa': 'ஆமா', 'venum': 'வேணும்', 'vendam': 'வேண்டாம்',
    'mudiyum': 'முடியும்', 'mudiyathu': 'முடியாது',
    'poren': 'போறேன்', 'varen': 'வாறேன்', 'seyren': 'செய்றேன்',
    'paaru': 'பாரு', 'kelu': 'கேளு', 'sollu': 'சொல்லு',
    'veedu': 'வீடு', 'velai': 'வேலை',
    'saapadu': 'சாப்பாடு', 'thanni': 'தண்ணி',
    'naal': 'நாள்', 'iravu': 'இரவு', 'paer': 'பேர்',
    'ungal': 'உங்கள்', 'enakku': 'எனக்கு', 'unakku': 'உனக்கு',
    'taooru': 'ஊரு', 'ill': 'இல்ல', 'illai': 'இல்லை',
    'nee': 'நீ', 'illa': 'இல்ல',
  };

  // ── Malayalam: Roman → Malayalam script ───────────────────────────────────
  static const Map<String, String> _malayalamMap = {
    'njan': 'ഞാൻ', 'njaan': 'ഞാൻ', 'mlnee': 'നീ', 'ningal': 'നിങ്ങൾ',
    'mlavan': 'അവൻ', 'mlaval': 'അവൾ', 'nammal': 'നമ്മൾ', 'njangal': 'ഞങ്ങൾ',
    'mlavar': 'അവർ', 'athu': 'അത്', 'ith': 'ഇത്',
    'enthanu': 'എന്താണ്', 'enthu': 'എന്ത്',
    'evide': 'എവിടെ', 'eppol': 'എപ്പോൾ', 'mleppe': 'എപ്പോ',
    'engane': 'എങ്ങനെ', 'endukond': 'എന്തുകൊണ്ട്',
    'aanu': 'ആണ്', 'mlalla': 'അല്ല', 'ille': 'ഇല്ലേ', 'illaa': 'ഇല്ല',
    'undu': 'ഉണ്ട്', 'undo': 'ഉണ്ടോ',
    'venam': 'വേണം', 'venda': 'വേണ്ട',
    'nalla': 'നല്ല', 'valiya': 'വലിയ', 'cheriya': 'ചെറിയ',
    'ellam': 'എല്ലാം', 'onnum': 'ഒന്നും',
    'ente': 'എന്റെ', 'ninte': 'നിന്റെ', 'avante': 'അവന്റെ',
    'mlveedu': 'വീട്', 'peru': 'പേര്', 'veellam': 'വെള്ളം',
    'panam': 'പണം', 'poya': 'പോയ', 'varum': 'വരും',
    'cheyyum': 'ചെയ്യും', 'kelkkum': 'കേൾക്കും',
    'namaskaram': 'നമസ്കാരം', 'nandi': 'നന്ദി', 'mlshari': 'ശരി',
    'ayyo': 'അയ്യോ', 'athe': 'അതേ',
    'divasam': 'ദിവസം', 'raathri': 'രാത്രി',
  };

  // ── Punjabi: Roman → Gurmukhi script ──────────────────────────────────────
  static const Map<String, String> _punjabiMap = {
    'pamain': 'ਮੈਂ', 'patu': 'ਤੂ', 'tusi': 'ਤੁਸੀਂ', 'tussi': 'ਤੁਸੀਂ',
    'paoh': 'ਉਹ', 'assi': 'ਅਸੀਂ', 'paohna': 'ਉਹਨਾਂ',
    'paki': 'ਕੀ', 'kithe': 'ਕਿੱਥੇ', 'kiven': 'ਕਿਵੇਂ', 'kaddon': 'ਕਦੋਂ',
    'pakyun': 'ਕਿਉਂ', 'pakitna': 'ਕਿੰਨਾ', 'pakaun': 'ਕੌਣ',
    'pahai': 'ਹੈ', 'pahain': 'ਹਨ', 'pasi': 'ਸੀ', 'pahoga': 'ਹੋਵੇਗਾ',
    'panahi': 'ਨਹੀਂ', 'panahiN': 'ਨਹੀਂ', 'pahaan': 'ਹਾਂ',
    'pamera': 'ਮੇਰਾ', 'pameri': 'ਮੇਰੀ', 'patera': 'ਤੇਰਾ', 'pateri': 'ਤੇਰੀ',
    'saada': 'ਸਾਡਾ', 'saadi': 'ਸਾਡੀ',
    'panaam': 'ਨਾਮ', 'paghar': 'ਘਰ', 'pakaam': 'ਕੰਮ', 'papani': 'ਪਾਣੀ',
    'roti': 'ਰੋਟੀ', 'padin': 'ਦਿਨ', 'paraat': 'ਰਾਤ',
    'paja': 'ਜਾ', 'paaa': 'ਆ', 'padekh': 'ਦੇਖ', 'pasun': 'ਸੁਣ',
    'sat': 'ਸਤ', 'sri': 'ਸ੍ਰੀ', 'akal': 'ਅਕਾਲ',
    'pashukriya': 'ਸ਼ੁਕਰੀਆ',
    'changa': 'ਚੰਗਾ', 'changi': 'ਚੰਗੀ', 'mada': 'ਮਾੜਾ',
    'vadda': 'ਵੱਡਾ', 'pabahut': 'ਬਹੁਤ',
    'kita': 'ਕੀਤਾ', 'honda': 'ਹੁੰਦਾ',
    'papyaar': 'ਪਿਆਰ', 'padost': 'ਦੋਸਤ', 'pabhai': 'ਭਾਈ',
  };

  // ── Urdu: Roman → Urdu script ─────────────────────────────────────────────
  static const Map<String, String> _urduMap = {
    'urmain': 'میں', 'urtum': 'تم', 'uraap': 'آپ',
    'urwoh': 'وہ', 'urhum': 'ہم', 'uryeh': 'یہ',
    'urkya': 'کیا', 'urkahan': 'کہاں', 'urkaise': 'کیسے',
    'urkab': 'کب', 'urkyun': 'کیوں', 'urkitna': 'کتنا', 'urkaun': 'کون',
    'urhai': 'ہے', 'urhain': 'ہیں', 'urtha': 'تھا', 'urthi': 'تھی',
    'urnahi': 'نہیں', 'urnahin': 'نہیں', 'urhaan': 'ہاں',
    'urtumhara': 'تمہارا', 'urtumhari': 'تمہاری',
    'uraapka': 'آپکا', 'uraapki': 'آپکی',
    'urnaam': 'نام', 'urghar': 'گھر', 'urkaam': 'کام', 'urpani': 'پانی',
    'urkhana': 'کھانا', 'urdin': 'دن', 'urraat': 'رات',
    'urbhai': 'بھائی', 'urbehen': 'بہن',
    'urbahut': 'بہت', 'urthoda': 'تھوڑا', 'ursab': 'سب',
    'uraur': 'اور', 'urlekin': 'لیکن',
    'urachha': 'اچھا', 'urbura': 'برا',
    'urja': 'جا', 'urkaro': 'کرو', 'urbatao': 'بتاؤ',
    'shukriya': 'شکریہ', 'meherbani': 'مہربانی',
    'assalam': 'السلام', 'walaikum': 'وعلیکم',
    'urpyaar': 'پیار', 'urmohabbat': 'محبت',
  };

  // ── Nepali: Roman → Devanagari (Nepali) ───────────────────────────────────
  static const Map<String, String> _nepaliMap = {
    'tapai': 'तपाई', 'tapain': 'तपाईं', 'nema': 'म',
    'hami': 'हामी', 'timi': 'तिमी', 'uniharu': 'उनीहरू',
    'neke': 'के', 'kaha': 'कहाँ', 'kasari': 'कसरी', 'kahile': 'कहिले',
    'kina': 'किन', 'kati': 'कति', 'neko': 'को',
    'chha': 'छ', 'chhan': 'छन्', 'thiyo': 'थियो',
    'hoina': 'होइन', 'haina': 'हैन',
    'mero': 'मेरो', 'timro': 'तिम्रो', 'tapaiako': 'तपाईंको',
    'usko': 'उस्को', 'hamro': 'हाम्रो',
    'nenaam': 'नाम', 'neghar': 'घर', 'nekaam': 'काम', 'nepani': 'पानी',
    'nekhana': 'खाना', 'nedin': 'दिन', 'neraat': 'रात',
    'ramro': 'राम्रो', 'naramro': 'नराम्रो', 'thulo': 'ठूलो', 'sano': 'सानो',
    'dherai': 'धेरै', 'ali': 'अलि', 'sabai': 'सबै',
    'nera': 'र', 'tara': 'तर',
    'nega': 'जा', 'neaa': 'आ', 'negar': 'गर',
    'namaskar': 'नमस्कार', 'dhanyabad': 'धन्यवाद',
    'hajur': 'हजुर', 'sanchai': 'सञ्चै',
  };

  // ── Sinhala: Roman → Sinhala script ───────────────────────────────────────
  static const Map<String, String> _sinhalaMap = {
    'mama': 'මම', 'oba': 'ඔබ', 'eyaa': 'එයා', 'api': 'අපි',
    'meka': 'මේක', 'eka': 'එක',
    'mokakda': 'මොකක්ද', 'koheda': 'කොහෙද', 'kohomada': 'කොහොමද',
    'kawda': 'කාද', 'ayi': 'ඇයි', 'kiyada': 'කීයද',
    'tiyenawa': 'තියෙනවා', 'sinehe': 'නෑ', 'siow': 'ඔව්',
    'honda': 'හොඳ', 'narak': 'නරක', 'loku': 'ලොකු', 'podi': 'පොඩි',
    'mage': 'මගේ', 'obe': 'ඔබේ', 'eyage': 'එයාගේ',
    'gedara': 'ගෙදර', 'sinaam': 'නම', 'watura': 'වතුර',
    'kema': 'කෑම', 'dawasa': 'දවස', 'siraa': 'රෑ',
    'yanawa': 'යනවා', 'enawa': 'එනවා', 'karanawa': 'කරනවා',
    'ayubowan': 'ආයුබෝවන්', 'isthuti': 'ඉස්තූතිය',
    'hari': 'හරි', 'bohoma': 'බොහොම',
  };

  // ── Marathi: Roman → Devanagari (Marathi) ─────────────────────────────────
  static const Map<String, String> _marathiMap = {
    'marmi': 'मी', 'martu': 'तू', 'tumi': 'तुम्ही', 'marto': 'तो',
    'marti': 'ती', 'aamhi': 'आम्ही', 'aapan': 'आपण', 'marte': 'ते',
    'kay': 'काय', 'kuthe': 'कुठे', 'kasa': 'कसा', 'kasi': 'कशी',
    'kase': 'कसे', 'keva': 'केव्हा', 'kiti': 'किती', 'markon': 'कोण',
    'aahe': 'आहे', 'aahes': 'आहेस', 'naahi': 'नाही', 'hoy': 'होय',
    'nako': 'नको', 'hote': 'होते', 'hota': 'होता', 'hoti': 'होती',
    'changla': 'चांगला', 'changli': 'चांगली',
    'maza': 'माझा', 'mazi': 'माझी', 'maze': 'माझे',
    'tuza': 'तुझा', 'tuzi': 'तुझी', 'tyacha': 'त्याचा', 'ticha': 'तिचा',
    'marghar': 'घर', 'marnaam': 'नाव', 'marpan': 'पण', 'ani': 'आणि',
    'khup': 'खूप', 'marthoda': 'थोडा',
    'marja': 'जा', 'marye': 'ये',
    'marnamaste': 'नमस्ते', 'mardhanyawad': 'धन्यवाद',
    'jevan': 'जेवण', 'marpani': 'पाणी', 'mardin': 'दिन', 'marraat': 'रात',
    'mothi': 'मोठी', 'motha': 'मोठा', 'lahan': 'लहान',
  };

  // ── Bengali: Roman → Bengali script ───────────────────────────────────────
  static const Map<String, String> _bengaliMap = {
    'ami': 'আমি', 'bntumi': 'তুমি', 'apni': 'আপনি', 'bnse': 'সে',
    'amra': 'আমরা', 'tomra': 'তোমরা', 'bntara': 'তারা',
    'bnki': 'কি', 'kothay': 'কোথায়', 'kemon': 'কেমন', 'kobe': 'কবে',
    'keno': 'কেন', 'koto': 'কত', 'bnke': 'কে',
    'ache': 'আছে', 'nei': 'নেই', 'bnhaan': 'হ্যাঁ', 'bnna': 'না',
    'bhalo': 'ভালো', 'kharap': 'খারাপ', 'boro': 'বড়', 'choto': 'ছোট',
    'amar': 'আমার', 'tomar': 'তোমার', 'bntar': 'তার',
    'bari': 'বাড়ি', 'bnnaam': 'নাম', 'khabar': 'খাবার', 'jal': 'জল',
    'bndin': 'দিন', 'bnraat': 'রাত', 'kaj': 'কাজ',
    'bnja': 'যা', 'aso': 'আসো', 'bndekho': 'দেখো', 'shono': 'শোনো',
    'namoshkar': 'নমস্কার', 'dhonnobad': 'ধন্যবাদ',
    'onek': 'অনেক', 'ektu': 'একটু', 'bnsob': 'সব', 'kicu': 'কিছু',
    'kintu': 'কিন্তু', 'ebong': 'এবং', 'sundor': 'সুন্দর', 'khub': 'খুব',
  };

  // ── Gujarati: Roman → Gujarati script ─────────────────────────────────────
  static const Map<String, String> _gujaratiMap = {
    'guju': 'હું', 'gutu': 'તું', 'tame': 'તમે', 'gute': 'તે',
    'ame': 'અમે', 'aapane': 'આપણે', 'guteo': 'તેઓ',
    'shu': 'શું', 'kyan': 'ક્યાં', 'gukem': 'કેમ', 'kyare': 'ક્યારે',
    'keti': 'કેટલી', 'gukon': 'કોણ',
    'chhe': 'છે', 'nathi': 'નથી', 'guha': 'હા', 'guna': 'ના',
    'saru': 'સારું', 'motu': 'મોટું',
    'maro': 'મારો', 'mari': 'મારી', 'taro': 'તારો', 'tari': 'તારી',
    'gughar': 'ઘર', 'gunaam': 'નામ', 'gupani': 'પાણી',
    'divas': 'દિવસ', 'guraat': 'રાત', 'gukaam': 'કામ',
    'guja': 'જા', 'aao': 'આવો', 'juo': 'જુઓ',
    'gunamaste': 'નમસ્તે', 'dhanyavaad': 'ધન્યવાદ',
    'ghanu': 'ઘણું', 'thodu': 'થોડું', 'badhu': 'બધું',
    'ane': 'અને',
  };

  // ── Russian: Roman → Cyrillic ─────────────────────────────────────────────
  static const Map<String, String> _russianMap = {
    'privet': 'привет', 'zdravstvuyte': 'здравствуйте',
    'spasibo': 'спасибо', 'pozhaluysta': 'пожалуйста', 'izvinite': 'извините',
    'rusya': 'я', 'rusty': 'ты', 'ruson': 'он', 'rusona': 'она',
    'rusmy': 'мы', 'rusvy': 'вы', 'rusoni': 'они',
    'chto': 'что', 'gde': 'где', 'kogda': 'когда', 'pochemu': 'почему',
    'ruskto': 'кто', 'ruskak': 'как', 'skolko': 'сколько',
    'rusda': 'да', 'rusnet': 'нет', 'horosho': 'хорошо', 'ploho': 'плохо',
    'rusdom': 'дом', 'rusimya': 'имя', 'rusvoda': 'вода', 'ruseda': 'еда',
    'rusden': 'день', 'rusnoch': 'ночь', 'rusrabota': 'работа',
    'bolshoy': 'большой', 'malenkiy': 'маленький', 'ochen': 'очень',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MASTER CONVERTER
  // ═══════════════════════════════════════════════════════════════════════════
  String _convertRomanToNativeScript(String text, String langCode) {
    Map<String, String> map;
    switch (langCode) {
      case 'hi': map = _hindiMap; break;
      case 'te': map = _teluguMap; break;
      case 'kn': map = _kannadaMap; break;
      case 'ta': map = _tamilMap; break;
      case 'ml': map = _malayalamMap; break;
      case 'pa': map = _punjabiMap; break;
      case 'ur': map = _urduMap; break;
      case 'ne': map = _nepaliMap; break;
      case 'si': map = _sinhalaMap; break;
      case 'mr': map = _marathiMap; break;
      case 'bn': map = _bengaliMap; break;
      case 'gu': map = _gujaratiMap; break;
      case 'ru': map = _russianMap; break;
      default: return text;
    }
    if (map.isEmpty) return text;
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final converted = words.map((word) {
      final clean = word.replaceAll(RegExp(r'[^a-z]'), '');
      return map[clean] ?? word;
    }).toList();
    final result = converted.join(' ');
    debugPrint('Roman→NativeScript[$langCode]: "$text" → "$result"');
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROMANIZED WORD DETECTION
  // ═══════════════════════════════════════════════════════════════════════════
  static const Map<String, List<String>> _romanizedWords = {
    'hi': [
      'hai', 'hain', 'kya', 'aap', 'main', 'mein', 'tum', 'hum', 'yeh', 'woh',
      'nahi', 'nahin', 'kaise', 'kaisa', 'kahan', 'kyun', 'aur', 'lekin',
      'bahut', 'thoda', 'abhi', 'phir', 'sab', 'kuch', 'koi',
      'tumhara', 'tumhari', 'mera', 'meri', 'apna', 'apni', 'unka', 'unki',
      'naam', 'kaam', 'baat', 'din', 'raat', 'ghar',
      'achha', 'theek', 'sahi', 'galat', 'zyada',
      'khana', 'pani', 'dost', 'yaar', 'bhai', 'behen',
      'tha', 'thi', 'hoga', 'hogi', 'chahiye', 'sakta', 'sakti',
      'karo', 'batao', 'dekho', 'suno', 'chalo', 'ruko',
    ],
    'te': [
      'nenu', 'meeru', 'enti', 'ela', 'evaru', 'ekkada', 'enduku',
      'chala', 'konchem', 'ledu', 'undi', 'namaskaaram',
      'unnaru', 'unnav', 'avunu', 'kaadu',
      'nuvvu', 'peru', 'illu', 'tindi', 'neellu',
      'roju', 'raatri', 'vachindi', 'chestanu',
      'manchidi', 'cheddadi', 'pedda', 'chinna',
    ],
    'kn': [
      'nanu', 'neevu', 'avanu', 'avalu', 'naavu', 'nimma', 'enu',
      'hege', 'yaake', 'yelli', 'banni', 'ide', 'namaskara',
      'channagide', 'channagi', 'howdu', 'alla', 'sari',
      'mane', 'kelasa', 'neeru', 'oota', 'dina', 'hesaru',
      'dodda', 'chikka', 'hosa', 'dhanyavada', 'ooru', 'hogi', 'illa',
    ],
    'ta': [
      'naan', 'nee', 'avan', 'aval', 'namma', 'ungal', 'enna', 'eppo',
      'enge', 'eppadi', 'romba', 'konjam', 'illa', 'illai',
      'seri', 'vanakkam', 'nandri', 'theriyum', 'theriyala',
      'aamaa', 'venum', 'vendam', 'mudiyum', 'neenga',
      'iruku', 'iruken', 'veedu', 'velai', 'saapadu', 'thanni',
    ],
    'ml': [
      'njan', 'njaan', 'ningal', 'nammal', 'njangal',
      'enthanu', 'enthu', 'evide', 'eppol', 'engane',
      'aanu', 'ille', 'illaa', 'undu', 'venam', 'venda',
      'nalla', 'valiya', 'cheriya', 'ellam',
      'ente', 'ninte', 'avante', 'veellam',
      'namaskaram', 'nandi', 'ayyo',
    ],
    'pa': [
      'tusi', 'tussi', 'assi', 'kithe', 'kiven', 'kaddon',
      'changa', 'changi', 'mada', 'vadda',
      'sat', 'sri', 'akal',
      'saada', 'saadi', 'roti', 'honda', 'kita',
    ],
    'ur': [
      'shukriya', 'meherbani', 'assalam', 'walaikum',
      'mohabbat',
    ],
    'mr': [
      'kuthe', 'kasa', 'kasi', 'aahe', 'naahi',
      'hoy', 'nako', 'changla', 'changli',
      'maza', 'mazi', 'tuza', 'tuzi', 'ani', 'khup',
      'mothi', 'motha', 'lahan', 'jevan',
    ],
    'bn': [
      'ami', 'kemon', 'kothay', 'keno', 'ache', 'nei',
      'bhalo', 'kharap', 'amar', 'tomar', 'bari', 'khabar',
      'namoshkar', 'dhonnobad', 'onek', 'ektu',
      'kintu', 'ebong', 'sundor', 'khub',
    ],
    'gu': [
      'tame', 'shu', 'kyan', 'chhe', 'nathi',
      'saru', 'motu', 'maro', 'mari', 'taro', 'tari',
      'dhanyavaad', 'ghanu', 'thodu', 'aao',
    ],
    'ne': [
      'tapai', 'tapain', 'hami', 'timi', 'uniharu',
      'chha', 'chhan', 'thiyo', 'hoina', 'haina',
      'mero', 'timro', 'hamro',
      'ramro', 'naramro', 'thulo', 'sano',
      'dherai', 'sabai', 'namaskar', 'dhanyabad', 'hajur',
    ],
    'si': [
      'mama', 'oba', 'eyaa', 'api',
      'mokakda', 'koheda', 'kohomada', 'kawda', 'ayi',
      'tiyenawa', 'honda', 'narak',
      'mage', 'gedara', 'watura',
      'ayubowan', 'isthuti', 'hari', 'bohoma',
    ],
    'fr': [
      'bonjour', 'merci', 'oui', 'non', 'comment', 'vous', 'nous',
      'sont', 'avec', 'pour', 'mais', 'bien', 'tres', 'aussi',
      'bonsoir', 'salut', 'pardon', 'monsieur', 'madame', 'est',
    ],
    'de': [
      'hallo', 'danke', 'bitte', 'nein', 'ich', 'sie', 'wir',
      'das', 'ist', 'sind', 'haben', 'nicht', 'auch', 'aber',
      'guten', 'morgen', 'abend', 'sprechen', 'heissen', 'und', 'der',
    ],
    'es': [
      'hola', 'gracias', 'como', 'usted', 'nosotros',
      'muy', 'para', 'pero', 'todo', 'tambien',
      'buenos', 'dias', 'tardes', 'noches', 'llamas', 'que', 'por',
    ],
    'it': [
      'ciao', 'grazie', 'prego', 'stai', 'bene',
      'buongiorno', 'buonasera', 'scusa', 'sono', 'sei',
      'noi', 'voi', 'loro', 'che', 'del', 'della', 'con',
      'dove', 'quando', 'perche', 'quanto', 'chi', 'siamo',
    ],
    'pt': [
      'ola', 'obrigado', 'obrigada', 'sim',
      'voce', 'nos', 'muito', 'mas', 'tambem',
      'bom', 'boa', 'noite', 'tarde',
      'onde', 'quando', 'porque', 'quem', 'tudo', 'nada',
    ],
    'ru': [
      'privet', 'zdravstvuyte', 'spasibo', 'pozhaluysta',
      'chto', 'gde', 'kogda', 'pochemu', 'skolko',
      'horosho', 'ploho', 'ochen', 'bolshoy', 'malenkiy',
    ],
    'tr': [
      'merhaba', 'tesekkur', 'ederim', 'evet', 'hayir',
      'nasil', 'nerede', 'zaman', 'neden', 'kim',
      'ben', 'biz', 'siz', 'onlar',
      'iyi', 'kotu', 'buyuk', 'kucuk', 'cok', 'az',
      'gunaydin', 'geceler', 'tamam',
    ],
    'id': [
      'halo', 'terima', 'kasih', 'bagaimana',
      'dimana', 'kapan', 'mengapa', 'berapa', 'siapa',
      'saya', 'anda', 'kita', 'kami', 'mereka',
      'baik', 'buruk', 'besar', 'kecil', 'sangat', 'sedikit',
      'selamat', 'pagi', 'siang', 'malam',
    ],
    'ms': [
      'helo', 'awak', 'bila', 'mana',
      'awak', 'mereka', 'sangat',
      'petang',
    ],
    'sw': [
      'habari', 'asante', 'ndiyo', 'hapana', 'vipi',
      'wapi', 'lini', 'nini', 'nani',
      'mimi', 'wewe', 'yeye', 'sisi', 'nyinyi', 'wao',
      'nzuri', 'mbaya', 'kubwa', 'ndogo', 'sana', 'kidogo',
      'jambo', 'karibu', 'kwaheri', 'tafadhali',
    ],
    'ar': [
      'marhaba', 'shukran', 'aiwa', 'kaifa', 'ana', 'nahnu',
      'inshallah', 'habibi', 'yalla', 'tayib', 'ahlan',
      'sabah', 'masaa', 'layla',
    ],
    'ko': [
      'annyeong', 'annyeonghaseyo', 'gamsahamnida', 'aniyo',
      'eodi', 'eonje', 'wae', 'eolma', 'nugu',
      'uri', 'geu', 'geunyeo',
      'joayo', 'sileoyo', 'keuda', 'jakda', 'mani', 'jom',
    ],
    'ja': [
      'konnichiwa', 'arigatou', 'iie', 'doko',
      'itsu', 'naze', 'ikura', 'dare', 'nani',
      'watashi', 'anata', 'kare', 'kanojo', 'watashitachi',
      'warui', 'ookii', 'chiisai', 'totemo', 'sukoshi',
      'ohayou', 'konbanwa', 'sayonara', 'sumimasen',
    ],
  };

  String? _detectRomanizedLanguage(String text) {
    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));
    final Map<String, int> scores = {};
    for (final entry in _romanizedWords.entries) {
      int score = 0;
      for (final word in words) {
        final clean = word.replaceAll(RegExp(r'[^a-z]'), '');
        if (entry.value.contains(clean)) score++;
      }
      if (score > 0) scores[entry.key] = score;
    }
    if (scores.isEmpty) return null;
    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (best.value >= 1) return best.key;
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BCP CODE MAPPINGS
  // NOTE: ML Kit does NOT have TranslateLanguage.malayalam or .punjabi
  // Malayalam = TranslateLanguage.malayalam does not exist in current ML Kit
  // We route ml→ through English relay only; pa/ur use Hindi model as proxy
  // ═══════════════════════════════════════════════════════════════════════════
  static const Map<String, TranslateLanguage> _bcpToLang = {
    'af': TranslateLanguage.afrikaans, 'sq': TranslateLanguage.albanian,
    'ar': TranslateLanguage.arabic,    'be': TranslateLanguage.belarusian,
    'bn': TranslateLanguage.bengali,   'bg': TranslateLanguage.bulgarian,
    'ca': TranslateLanguage.catalan,   'zh': TranslateLanguage.chinese,
    'hr': TranslateLanguage.croatian,  'cs': TranslateLanguage.czech,
    'da': TranslateLanguage.danish,    'nl': TranslateLanguage.dutch,
    'en': TranslateLanguage.english,   'eo': TranslateLanguage.esperanto,
    'et': TranslateLanguage.estonian,  'fi': TranslateLanguage.finnish,
    'fr': TranslateLanguage.french,    'gl': TranslateLanguage.galician,
    'ka': TranslateLanguage.georgian,  'de': TranslateLanguage.german,
    'el': TranslateLanguage.greek,     'gu': TranslateLanguage.gujarati,
    'he': TranslateLanguage.hebrew,    'hi': TranslateLanguage.hindi,
    'hu': TranslateLanguage.hungarian, 'is': TranslateLanguage.icelandic,
    'id': TranslateLanguage.indonesian,'ga': TranslateLanguage.irish,
    'it': TranslateLanguage.italian,   'ja': TranslateLanguage.japanese,
    'kn': TranslateLanguage.kannada,   'ko': TranslateLanguage.korean,
    'lv': TranslateLanguage.latvian,   'lt': TranslateLanguage.lithuanian,
    'mk': TranslateLanguage.macedonian,'ms': TranslateLanguage.malay,
    'mt': TranslateLanguage.maltese,   'mr': TranslateLanguage.marathi,
    'no': TranslateLanguage.norwegian, 'fa': TranslateLanguage.persian,
    'pl': TranslateLanguage.polish,    'pt': TranslateLanguage.portuguese,
    'ro': TranslateLanguage.romanian,  'ru': TranslateLanguage.russian,
    'sk': TranslateLanguage.slovak,    'sl': TranslateLanguage.slovenian,
    'es': TranslateLanguage.spanish,   'sw': TranslateLanguage.swahili,
    'sv': TranslateLanguage.swedish,   'tl': TranslateLanguage.tagalog,
    'ta': TranslateLanguage.tamil,     'te': TranslateLanguage.telugu,
    'th': TranslateLanguage.thai,      'tr': TranslateLanguage.turkish,
    'uk': TranslateLanguage.ukrainian, 'ur': TranslateLanguage.urdu,
    'vi': TranslateLanguage.vietnamese,'cy': TranslateLanguage.welsh,
    // Malayalam & Punjabi use Hindi model as nearest supported proxy
    'ml': TranslateLanguage.hindi,     'pa': TranslateLanguage.hindi,
    'ne': TranslateLanguage.hindi,     'si': TranslateLanguage.english,
  };

  static const Map<String, String> _bcpToName = {
    'en': 'English',    'ta': 'Tamil',      'hi': 'Hindi',
    'te': 'Telugu',     'kn': 'Kannada',    'ml': 'Malayalam',
    'mr': 'Marathi',    'bn': 'Bengali',    'gu': 'Gujarati',
    'pa': 'Punjabi',    'ur': 'Urdu',       'ne': 'Nepali',
    'si': 'Sinhala',    'fr': 'French',     'de': 'German',
    'es': 'Spanish',    'it': 'Italian',    'pt': 'Portuguese',
    'ru': 'Russian',    'zh': 'Chinese',    'ja': 'Japanese',
    'ko': 'Korean',     'ar': 'Arabic',     'tr': 'Turkish',
    'vi': 'Vietnamese', 'th': 'Thai',       'id': 'Indonesian',
    'ms': 'Malay',      'nl': 'Dutch',      'pl': 'Polish',
    'sv': 'Swedish',    'sw': 'Swahili',    'tl': 'Filipino',
  };

  static const Map<String, String> _bcpToSpeechLocale = {
    'af': 'af-ZA', 'sq': 'sq-AL', 'ar': 'ar-SA', 'bn': 'bn-IN',
    'bg': 'bg-BG', 'ca': 'ca-ES', 'zh': 'zh-CN', 'hr': 'hr-HR',
    'cs': 'cs-CZ', 'da': 'da-DK', 'nl': 'nl-NL', 'en': 'en-IN',
    'et': 'et-EE', 'fi': 'fi-FI', 'fr': 'fr-FR', 'de': 'de-DE',
    'el': 'el-GR', 'gu': 'gu-IN', 'he': 'iw-IL', 'hi': 'hi-IN',
    'hu': 'hu-HU', 'id': 'id-ID', 'it': 'it-IT', 'ja': 'ja-JP',
    'kn': 'kn-IN', 'ko': 'ko-KR', 'lv': 'lv-LV', 'lt': 'lt-LT',
    'ms': 'ms-MY', 'mr': 'mr-IN', 'no': 'nb-NO', 'fa': 'fa-IR',
    'pl': 'pl-PL', 'pt': 'pt-BR', 'ro': 'ro-RO', 'ru': 'ru-RU',
    'sk': 'sk-SK', 'sl': 'sl-SI', 'es': 'es-ES', 'sw': 'sw-KE',
    'sv': 'sv-SE', 'tl': 'fil-PH','ta': 'ta-IN', 'te': 'te-IN',
    'th': 'th-TH', 'tr': 'tr-TR', 'uk': 'uk-UA', 'ur': 'ur-PK',
    'vi': 'vi-VN', 'cy': 'cy-GB', 'ml': 'ml-IN', 'pa': 'pa-IN',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MODEL MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════
  Future<bool> areModelsDownloaded() async {
    try { return await _modelManager.isModelDownloaded(_targetLang.bcpCode); }
    catch (e) { return false; }
  }

  Future<void> downloadModels({Function(double)? onProgress}) async {
    try {
      onProgress?.call(0.1);
      await _modelManager.downloadModel(_targetLang.bcpCode);
      onProgress?.call(1.0);
    } catch (e) { debugPrint('Model download error: $e'); rethrow; }
  }

  Future<void> loadModels() async {
    _isLoaded = true;
    await _refreshDownloadedLocales();
    debugPrint('ML Kit translator ready! Target: $_targetLangName');
  }

  List<String> _downloadedSpeechLocales = ['en-IN'];
  List<String> get downloadedSpeechLocales => _downloadedSpeechLocales;

  Future<void> _refreshDownloadedLocales() async {
    final locales = <String>[];
    for (final entry in _bcpToSpeechLocale.entries) {
      try {
        final downloaded = await _modelManager.isModelDownloaded(entry.key);
        if (downloaded) locales.add(entry.value);
      } catch (_) {}
    }
    if (!locales.contains('en-IN')) locales.add('en-IN');
    _downloadedSpeechLocales = locales;
  }

  void setTargetLanguage(TranslateLanguage lang, String name) {
    if (_targetLang == lang) return;
    _targetLang = lang;
    _targetLangName = name;
    for (final t in _translators.values) t.close();
    _translators.clear();
  }

  void reloadIfNeeded(TranslateLanguage lang) {
    if (_targetLang == lang) {
      for (final t in _translators.values) t.close();
      _translators.clear();
    }
  }

  OnDeviceTranslator _getTranslator(TranslateLanguage src, TranslateLanguage tgt) {
    final key = '${src.bcpCode}_${tgt.bcpCode}';
    if (!_translators.containsKey(key)) {
      _translators[key] = OnDeviceTranslator(sourceLanguage: src, targetLanguage: tgt);
    }
    return _translators[key]!;
  }

  String _lastDetectedLangName = 'Auto';
  String get lastDetectedLangName => _lastDetectedLangName;

  String _rollingBuffer = '';
  int _sentenceCount = 0;

  void clearDetectionBuffer() {
    _sentenceCount++;
    if (_sentenceCount >= 3) { _rollingBuffer = ''; _sentenceCount = 0; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN TRANSLATION PIPELINE
  // ═══════════════════════════════════════════════════════════════════════════
  Future<String> translateOnMainThread(String text, {
    String sourceLang = 'eng_Latn',
    String targetLang = 'tam_Taml',
  }) async {
    if (text.trim().isEmpty) return '';
    try {
      // ── Step 1: Detect language ───────────────────────────────────────────
      final romanDetected = _detectRomanizedLanguage(text);
      String detectedCode = 'en';

      if (romanDetected != null) {
        detectedCode = romanDetected;
        debugPrint('Romanized detect: $detectedCode for "$text"');
      } else {
        _rollingBuffer = ('$_rollingBuffer $text').trim();
        if (_rollingBuffer.length > 200) {
          _rollingBuffer = _rollingBuffer.substring(_rollingBuffer.length - 200);
        }
        final candidates = await _languageIdentifier
            .identifyPossibleLanguages(_rollingBuffer);
        double bestConf = 0.0;
        for (final c in candidates) {
          final base = c.languageTag.split('-').first;
          if (c.confidence > bestConf && _bcpToLang.containsKey(base)) {
            bestConf = c.confidence;
            detectedCode = base;
          }
        }
        debugPrint('ML Kit detect: $detectedCode conf=${bestConf.toStringAsFixed(2)}');
      }

      _lastDetectedLangName = _bcpToName[detectedCode] ?? detectedCode.toUpperCase();
      final sourceLangEnum = _bcpToLang[detectedCode] ?? TranslateLanguage.english;

      if (sourceLangEnum == _targetLang) {
        debugPrint('Source == Target, skipping');
        return '';
      }

      // ── Step 2: Convert Roman → Native Script ────────────────────────────
      const nativeScriptLangs = {
        'hi', 'te', 'kn', 'ta', 'ml', 'pa', 'ur',
        'ne', 'si', 'mr', 'bn', 'gu', 'ru',
      };
      String textToTranslate = text;
      if (nativeScriptLangs.contains(detectedCode)) {
        textToTranslate = _convertRomanToNativeScript(text, detectedCode);
      }

      // ── Step 3: Download source model if needed ───────────────────────────
      final srcDownloaded = await _modelManager.isModelDownloaded(sourceLangEnum.bcpCode);
      if (!srcDownloaded) {
        debugPrint('Downloading model: ${sourceLangEnum.bcpCode}');
        await _modelManager.downloadModel(sourceLangEnum.bcpCode);
      }

      // ── Step 4: Translate ─────────────────────────────────────────────────
      String finalResult;

      if (sourceLangEnum == TranslateLanguage.english) {
        final tgtDownloaded = await _modelManager.isModelDownloaded(_targetLang.bcpCode);
        if (!tgtDownloaded) await _modelManager.downloadModel(_targetLang.bcpCode);
        finalResult = await _getTranslator(TranslateLanguage.english, _targetLang)
            .translateText(textToTranslate);
        debugPrint('EN→$_targetLangName: "$textToTranslate" → "$finalResult"');

      } else if (_targetLang == TranslateLanguage.english) {
        finalResult = await _getTranslator(sourceLangEnum, TranslateLanguage.english)
            .translateText(textToTranslate);
        debugPrint('${sourceLangEnum.bcpCode}→EN: "$textToTranslate" → "$finalResult"');

      } else {
        // 2-step relay: Source → English → Target
        final englishText = await _getTranslator(sourceLangEnum, TranslateLanguage.english)
            .translateText(textToTranslate);
        debugPrint('Step1 (${sourceLangEnum.bcpCode}→en): "$textToTranslate" → "$englishText"');

        if (englishText.trim().isEmpty) return '';

        final tgtDownloaded = await _modelManager.isModelDownloaded(_targetLang.bcpCode);
        if (!tgtDownloaded) await _modelManager.downloadModel(_targetLang.bcpCode);
        finalResult = await _getTranslator(TranslateLanguage.english, _targetLang)
            .translateText(englishText);
        debugPrint('Step2 (en→$_targetLangName): "$englishText" → "$finalResult"');
      }

      return finalResult;

    } catch (e) {
      debugPrint('Translation error: $e');
      try {
        return await _getTranslator(TranslateLanguage.english, _targetLang)
            .translateText(text);
      } catch (_) { return text; }
    }
  }

  void dispose() {
    for (final t in _translators.values) t.close();
    _translators.clear();
    _languageIdentifier.close();
    _isLoaded = false;
  }
}
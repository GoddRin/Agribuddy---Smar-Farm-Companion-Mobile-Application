import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class AppLoc {
  static const Map<String, String> _tl = {
    // Auth & Onboarding
    'Welcome Back': 'Maligayang Pagbabalik',
    'Sign in to your farm account': 'Mag-sign in sa iyong account',
    'Username': 'Username',
    'Password': 'Password',
    'Enter your username': 'Ilagay ang iyong username',
    'Enter your password': 'Ilagay ang iyong password',
    'Sign In': 'Mag-sign In',
    "Don't have an account? ": "Wala pang account? ",
    'Register': 'Mag-rehistro',
    'Create Account': 'Gumawa ng Account',
    'Set up your farm profile': 'I-setup ang iyong farm profile',
    'Full Name': 'Buong Pangalan',
    'Email (optional)': 'Email (opsyonal)',
    'Farm Name': 'Pangalan ng Farm',
    'Confirm Password': 'Kumpirmahin ang Password',
    'Sign Out': 'Mag-sign Out',
    
    // Bottom Nav & Titles
    'Home': 'Home',
    'Dashboard': 'Dashboard',
    'My Crops': 'Aking Tanim',
    'Crops': 'Tanim',
    'Tasks': 'Gawain',
    'Logs': 'Talaan',
    'More': 'Iba pa',
    'Settings': 'Mga Setting',
    'Farm Calendar': 'Kalendaryo ng Farm',
    'Expense Tracker': 'Listahan ng Gastos',
    'Reports': 'Mga Ulat',
    
    // Dashboard
    'Tip of the Day': 'Tip para sa Araw na ito',
    'Quick Actions': 'Mabilisang Aksyon',
    'Add Log': 'Tala',
    'Add Task': 'Gawain',
    'Add Expense': 'Gastos',
    'Ask Pedro': 'Kay Pedro',

    // Crops
    'Add Your First Crop': 'Magdagdag ng Unang Tanim',
    'No crops yet': 'Wala pang tanim',
    'Health': 'Kalusugan',
    'Good': 'Mabuti',
    'Fair': 'Pwede na',
    'Poor': 'Mahina',
    'Add New Crop': 'Magdagdag ng Tanim',
    'Crop Name': 'Pangalan ng Tanim',
    'Block / Location': 'Pwesto / Lokasyon',
    'Growth Stage': 'Yugto ng Paglaki',
    'Planted Date': 'Petsa ng Pagtatanim',
    'Expected Harvest': 'Inaasahang Ani',
    'Add Crop': 'Idagdag ang Tanim',

    // Stages
    'Seedling': 'Punla',
    'Vegetative': 'Tumutubo',
    'Flowering': 'Namumulaklak',
    'Fruiting': 'Namumunga',
    'Established': 'Matatag na',
    'Ready to Harvest': 'Handa nang Anihin',

    // Tasks
    'Task Planner': 'Plano ng Gawain',
    'Upcoming': 'Susunod',
    'Today': 'Ngayon',
    'Done': 'Tapos na',
    'No tasks found.': 'Walang nakitang gawain.',
    'Overdue!': 'Lagpas sa oras!',
    'Add New Task': 'Magdagdag ng Gawain',
    'Task Title': 'Pangalan ng Gawain',
    'Category': 'Kategorya',
    'Due Date': 'Petsa',
    'Time': 'Oras',
    'Repeat': 'Ulitin',
    'Link to Crop': 'I-link sa Tanim (Opsyonal)',
    
    // Task / Log Categories
    'Irrigation': 'Patubig',
    'Fertilizer': 'Abono',
    'Spraying': 'Pag-spray',
    'Harvesting': 'Pag-aani',
    'Maintenance': 'Pagpapanatili',
    'Observation': 'Obserbasyon',
    'Planting': 'Pagtatanim',
    'Watering': 'Pagdidilig',
    'Pest Control': 'Peste Control',
    'Other': 'Iba pa',

    // Expenses
    'Total Expenses': 'Kabuuang Gastos',
    'Tap + to add your first expense': 'I-tap ang + para magdagdag',
    'Add New Expense': 'Magdagdag ng Gastos',
    'Description': 'Paglalarawan',
    'Amount (₱)': 'Halaga (₱)',
    'Date': 'Petsa',

    // Settings
    'Account': 'Account',
    'Language': 'Wika',
    'English': 'English',
    'Filipino (Tagalog)': 'Filipino (Tagalog)',
    'Theme': 'Tema',
    'Light Mode': 'Maliwanag na Tema',
    'Dark Mode': 'Madilim na Tema',
    'Gemini API Key': 'Gemini API Key',
    'Connected': 'Konektado',
    'Not Set': 'Hindi Naka-set',
    'Save API Key': 'I-save ang Key',
    'Saved!': 'Naka-save!',
    'Clear': 'Burahin',
    'About': 'Tungkol sa App',
    'Version': 'Bersyon',

    // Ask Pedro
    'Magtanong kay Mang Pedro...': 'Magtanong kay Mang Pedro...',
    'Input key in Settings for smarter AI': 'Maglagay ng key sa Settings para mas tumalino',
    'Set Key': 'I-set',
    'AI Active': 'AI Konektado',
    'Pattern Match': 'Offline AI',

    // Common
    'Save': 'I-save',
    'Cancel': 'Kanselahin',
    'Update Stage': 'I-update ang Yugto',
    'Remove': 'Tanggalin',
    'Not set': 'Hindi pa naka-set',
    'Tap a date to see events': 'Pumindot ng petsa para makita ang events',
    'No events on this day': 'Walang events sa araw na ito',
  };

  static String t(String key, String locale) {
    if (locale == 'en') return key; // 'en' is default base string
    return _tl[key] ?? key;
  }
}

// Helper extension to quickly translate any string using context + provider
extension TransProvider on WidgetRef {
  String t(String text) {
    final lang = watch(settingsProvider)['language'] ?? 'en';
    return AppLoc.t(text, lang);
  }
}

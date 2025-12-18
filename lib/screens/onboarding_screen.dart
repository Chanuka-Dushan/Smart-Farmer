import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/l10n.dart';
import '../services/l10n_extension.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('selected_language') ?? 'en';
    });
  }

  // Language-specific onboarding data
  List<Map<String, String>> get _onboardingData {
    switch (_currentLanguage) {
      case 'si': // Sinhala
        return [
          {
            "title": "ආයු කාලය පුරෝකථනය කරන්න",
            "desc": "AI පුරෝකථන විශ්ලේෂණය භාවිතයෙන් ඔබේ ට්‍රැක්ටර් කොටස් කවදාද අසාර්ථක වනු ඇත්දැයි නිවැරදිව දැනගන්න.",
            "icon": "alarm"
          },
          {
            "title": "ඇඳීම හඳුනාගන්න",
            "desc": "කළ, ඉරිතැලීම් සහ හානිය ක්ෂණිකව හඳුනාගැනීමට ඕනෑම කොටසක් ඡායාරූපයක් ගන්න.",
            "icon": "camera_alt"
          },
          {
            "title": "සත්‍යාපිත සැපයුම්කරුවන්",
            "desc": "ආසන්නයේ අව්‍යාජ කොටස් සොයාගෙන බ්ලොක්චේන් තාක්ෂණය සමඟ ඒවා ආරක්ෂිත කරන්න.",
            "icon": "security"
          },
        ];
      case 'ta': // Tamil
        return [
          {
            "title": "ஆயுட்காலத்தை கணிக்கவும்",
            "desc": "AI கணிப்பு பகுப்பாய்வைப் பயன்படுத்தி உங்கள் டிராக்டர் பாகங்கள் எப்போது தோல்வியடையும் என்பதை துல்லியமாக அறியவும்.",
            "icon": "alarm"
          },
          {
            "title": "தேய்மானத்தைக் கண்டறியவும்",
            "desc": "துரு, விரிசல் மற்றும் சேதத்தை உடனடியாக கண்டறிய எந்த பாகத்தின் புகைப்படத்தையும் எடுக்கவும்.",
            "icon": "camera_alt"
          },
          {
            "title": "சரிபார்க்கப்பட்ட சப்ளையர்கள்",
            "desc": "அருகிலுள்ள உண்மையான பாகங்களைக் கண்டறிந்து பிளாக்செயின் தொழில்நுட்பத்துடன் அவற்றைப் பாதுகாக்கவும்.",
            "icon": "security"
          },
        ];
      default: // English
        return [
          {
            "title": "Predict Lifespan",
            "desc": "Know exactly when your tractor parts will fail using AI Predictive Analytics.",
            "icon": "alarm"
          },
          {
            "title": "Detect Wear",
            "desc": "Take a photo of any part to instantly detect rust, cracks, and damage.",
            "icon": "camera_alt"
          },
          {
            "title": "Verified Suppliers",
            "desc": "Find authentic parts nearby and secure them with Blockchain technology.",
            "icon": "security"
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return OnboardingContent(
                    title: context.tr(_onboardingData[index]['title']!),
                    desc: context.tr(_onboardingData[index]['desc']!),
                    iconData: _getIconData(_onboardingData[index]['icon']!),
                  );
                },
              ),
            ),
            // Navigation Dots & Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 5),
                        height: 10,
                        width: _currentPage == index ? 20 : 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        Navigator.pushReplacementNamed(context, '/login');
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1
                          ? context.tr('get_started')
                          : context.tr('next'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper to map string to IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'alarm': return Icons.access_alarm;
      case 'camera_alt': return Icons.camera_alt;
      case 'security': return Icons.verified_user;
      default: return Icons.info;
    }
  }
}

// Widget for individual slide content
class OnboardingContent extends StatelessWidget {
  final String title, desc;
  final IconData iconData;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.desc,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 150, color: Theme.of(context).primaryColor),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Onboarding Data based on your Proposal
  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Predict Lifespan",
      "desc": "Know exactly when your tractor parts will fail using AI Predictive Analytics.",
      "icon": "alarm" // Using icon names to map later
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
                    title: _onboardingData[index]['title']!,
                    desc: _onboardingData[index]['desc']!,
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
                          ? "Get Started"
                          : "Next",
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
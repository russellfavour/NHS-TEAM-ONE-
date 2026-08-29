import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> pages = [
    {
      'title': 'Report Crimes In Real-time',
      'description': 'Submit detailed crime reports with GPS location, photos, and audio evidence to help keep your community safe.',
      'icon': Icons.report_problem_outlined,
    },
    {
      'title': 'Get Safe Routes & Alerts',
      'description': 'Receive real-time safety alerts about nearby incidents and plan safer routes using AI-powered analysis.',
      'icon': Icons.map_outlined,
    },
    {
      'title': 'Stay Together, Safer Together',
      'description': 'Connect with your community. Report suspicious activity, verify reports from others, and build a safer neighborhood.',
      'icon': Icons.groups_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page['icon'] as IconData, size: 100, color: AppColors.primaryGreen),
                        const SizedBox(height: 48),
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['description']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicators and buttons
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primaryGreen : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < pages.length - 1) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
                    child: Text(_currentPage == pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

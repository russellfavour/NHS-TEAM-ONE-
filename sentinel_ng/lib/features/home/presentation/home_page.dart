import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboard(),
    const CrimeMapPage(),
    const SizedBox.shrink(), // FAB placeholder
    const NotificationsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: _buildFAB(context),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != 2) { // Skip FAB position
              setState(() => _currentIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''), // Spacer for FAB
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SOS button (top)
        FloatingActionButton.extended(
          onPressed: () => context.push('/sos-emergency'),
          backgroundColor: AppColors.alertRed,
          elevation: 4,
          icon: const Icon(Icons.warning_amber_rounded, size: 20),
          label: const Text('SOS', style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 16),
        // Main FAB (center) - Report Crime
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _showReportingMenu(context),
            backgroundColor: AppColors.primaryGreen,
            elevation: 6,
            child: const Icon(Icons.add, size: 32),
          ),
        ),
      ],
    );
  }

  void _showReportingMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 16,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('What would you like to do?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _menuOption(Icons.report_problem, 'Report a Crime', AppColors.alertRed, () {
              Navigator.pop(context);
              context.push('/reporting-wizard');
            }),
            _menuOption(Icons.route, 'Safe Route Planner', AppColors.primaryGreen, () {
              Navigator.pop(context);
              context.push('/safe-route');
            }),
            _menuOption(Icons.local_police, 'Find Safe Places', Colors.blue.shade700, () {}),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _menuOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}

/// Home Dashboard - Main area matching the design exactly
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 60,
          floating: true,
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Hello, Samuel 👋', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Stay safe, Stay informed.', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  child: Icon(Icons.person_outline, color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Safety Score Card - Green gradient matching design
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF81C784), const Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your Safety Score', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 8),
                  Row(children: [
                    // Circular gauge
                    SizedBox(width: 100, height: 100, child: Stack(alignment: Alignment.center, children: [
                      SizedBox(width: 100, height: 100, child: CircularProgressIndicator(
                        value: 0.82,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('82', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Very safe', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
                      ]),
                    ])),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.trending_up, size: 18, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('12% from Last Week', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
                      ]),
                      const SizedBox(height: 16),
                      // Mini bar chart visualization
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        _miniBar(0.5),
                        _miniBar(0.7),
                        _miniBar(0.4),
                        _miniBar(0.9),
                        _miniBar(0.82),
                      ]),
                    ])),
                  ]),
                ]),
              ),

              const SizedBox(height: 24),

              // Quick Actions - 4 cards in a row
              Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _quickActionCard(Icons.report_problem, 'Report\nCrime', AppColors.alertRed),
                _quickActionCard(Icons.location_on, 'SOS', Colors.red.shade700),
                _quickActionCard(Icons.map_outlined, 'Safe\nRoute', AppColors.primaryGreen),
                _quickActionCard(Icons.chat_bubble_outline, 'AI\nAssistant', Colors.blue.shade700),
              ]),

              const SizedBox(height: 24),

              // Recent Alerts
              Text('Recent Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              _alertCard(
                'A',
                'Armed Robbery',
                'ikeja Lagos',
                '10 min ago',
                AppColors.alertRed,
              ),
              const SizedBox(height: 12),
              
              _alertCard(
                'T',
                'Theft',
                'ikeja Lagos',
                '25 min ago',
                Colors.blue.shade800,
              ),
              const SizedBox(height: 12),
              
              _alertCard(
                '👤',
                'Suspicious Activity',
                'Yeba Lagos',
                '1hr min ago',
                Colors.orange.shade700,
              ),

              const SizedBox(height: 32), // Bottom padding for FAB
            ])),
          ),
      ],
    );
  }

  Widget _miniBar(double height) {
    return Container(
      width: 8,
      height: 40 * height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _quickActionCard(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _alertCard(String initial, String title, String location, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        // Colored circle with initial
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(initial, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text(location, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ])),
        Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ]),
    );
  }
}

/// Crime Map Page - Interactive map with markers
class CrimeMapPage extends StatelessWidget {
  const CrimeMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Map placeholder (will be replaced with google_maps_flutter)
      Container(color: Colors.grey[100]),
      
      // Filter bar at top
      Positioned(top: 50, left: 16, right: 16, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _filterChip('All', true),
          const SizedBox(width: 8),
          _filterChip('Robbery', false),
          const SizedBox(width: 8),
          _filterChip('Theft', false),
          const SizedBox(width: 8),
          _filterChip('Assault', false),
          const SizedBox(width: 8),
          _filterChip('Safe Places', false),
        ])),
      )),

      // Map legend at bottom
      Positioned(bottom: 100, left: 16, child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          _legendItem(AppColors.alertRed, 'High Risk'),
          _legendItem(Colors.orange, 'Medium Risk'),
          _legendItem(AppColors.primaryGreen, 'Low Risk'),
        ]),
      )),

      // Center text for placeholder
      const Center(child: Text('Interactive Crime Map\n(Will use google_maps_flutter)\n\nShows verified reports,\ncommunity alerts, and\nsafe place markers', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey))),
    ]);
  }

  Widget _filterChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
      selectedColor: AppColors.primaryGreen.withOpacity(0.15),
      checkmarkColor: AppColors.primaryGreen,
      backgroundColor: Colors.white,
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 12)),
    ]));
  }
}

/// Notifications Page - Categorized alert list
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Category tabs
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _categoryTab('All', true),
          _categoryTab('Alerts', false),
          _categoryTab('Updates', false),
          _categoryTab('System', false),
        ])),
      ),
      
      // Notification list
      Expanded(child: ListView(
        children: [
          _notificationCard(Icons.warning_amber_rounded, 'New crime reported nearby', 'Armed robbery near your area - 2 hours ago', Colors.orange, true),
          _notificationCard(Icons.verified, 'Your report was verified', 'Report #SR1234 has been verified by admin', Colors.green, false),
          _notificationCard(Icons.info_outline, 'System maintenance scheduled', 'Scheduled for tonight 10PM - 12AM', Colors.blue, true),
          _notificationCard(Icons.local_police, 'Police patrol in your area', 'Increased police presence reported near Victoria Island', AppColors.primaryGreen, false),
        ],
      ))
    ]);
  }

  Widget _categoryTab(String label, bool selected) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
      selectedColor: AppColors.primaryGreen.withOpacity(0.15),
      checkmarkColor: AppColors.primaryGreen,
    ));
  }

  Widget _notificationCard(IconData icon, String title, String subtitle, Color color, bool isNew) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ])),
        if (isNew) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.alertRed, shape: BoxShape.circle)),
      ]),
    );
  }
}

/// Profile Page - User settings and info
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      // Profile header
      Container(padding: const EdgeInsets.all(24), child: Column(children: [
        CircleAvatar(radius: 50, backgroundColor: AppColors.primaryGreen.withOpacity(0.1), child: Icon(Icons.person, size: 50, color: AppColors.primaryGreen)),
        const SizedBox(height: 16),
        Text('Samuel Adeyemi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text('samuel@example.com', style: TextStyle(color: Colors.grey[600])),
      ])),

      const Divider(),

      // Menu items
      _menuTile(Icons.report_problem, 'My Reports', () => context.push('/my-reports')),
      _menuTile(Icons.star, 'Safety Score Details', () => context.push('/safety-score-detail')),
      _menuTile(Icons.notifications, 'Notification Settings', () {}),
      _menuTile(Icons.phone, 'Emergency Contacts', () => context.push('/emergency-contacts')),
      _menuTile(Icons.bookmark, 'Saved Locations', () => context.push('/saved-locations')),
      _menuTile(Icons.settings, 'Settings', () {}),

      const Divider(),

      // Logout
      ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Logout', style: TextStyle(color: Colors.red)), onTap: () {}),
    ]);
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(leading: CircleAvatar(child: Icon(icon, size: 20)), title: Text(label), trailing: Icon(Icons.chevron_right, color: Colors.grey[400]), onTap: onTap);
  }
}

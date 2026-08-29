/// Application-wide string constants
class AppStrings {
  // App branding
  static const String appName = 'Sentinel NG';
  static const String appTagline = 'Safer Communities, Together';
  
  // Onboarding
  static const List<OnboardingContent> onboardingContents = [
    OnboardingContent(
      title: 'Report Crimes In Real-time',
      description: 'Submit detailed crime reports with GPS location, photos, and audio evidence to help keep your community safe.',
      icon: 'assets/icons/report.svg',
    ),
    OnboardingContent(
      title: 'Get Safe Routes & Alerts',
      description: 'Receive real-time safety alerts about nearby incidents and plan safer routes using our AI-powered route planner.',
      icon: 'assets/icons/map.svg',
    ),
    OnboardingContent(
      title: 'Stay Together, Safer Together',
      description: 'Connect with your community. Report suspicious activity, verify reports from others, and build a safer neighborhood.',
      icon: 'assets/icons/community.svg',
    ),
  ];

  // Auth
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to continue to Sentinel NG';
  static const String registerTitle = 'Create Account';
  static const String registerSubtitle = 'Join your community safety network';
  static const String emailLabel = 'Email Address';
  static const String passwordLabel = 'Password';
  static const String nameLabel = 'Full Name';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String loginButton = 'Sign In';
  static const String registerButton = 'Create Account';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = "Don't have an account?";
  static const String hasAccount = 'Already have an account?';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';

  // Home Dashboard
  static const String homeTitle = 'Home';
  static const String safetyScoreLabel = 'Your Safety Score';
  static const String quickActionsTitle = 'Quick Actions';
  static const String recentAlertsTitle = 'Recent Alerts';
  static const String reportCrime = 'Report Crime';
  static const String sosEmergency = 'SOS Emergency';
  static const String safeRoute = 'Safe Route';
  static const String viewMap = 'View Map';

  // Reporting Wizard
  static const String reportingTitle = 'Report a Crime';
  static const String selectCrimeType = 'Select Crime Type';
  static const String selectLocation = 'Select Location';
  static const String incidentDescription = 'Incident Description';
  static const String witnessInformation = 'Witness Information';
  static const String suspectInformation = 'Suspect Information';
  static const String evidenceCollection = 'Evidence Collection';
  static const String previewReport = 'Preview Report';
  static const String submitReport = 'Submit Report';
  static const String reportSubmitted = 'Report Submitted Successfully!';
  static const String reportIdPrefix = '#SR';

  // Crime Types
  static const List<String> crimeTypes = [
    'Armed Robbery',
    'Theft',
    'Assault',
    'Vandalism',
    'Cyber Crime',
    'Suspicious Activity',
    'Others',
  ];

  // SOS Emergency
  static const String sosTitle = 'Emergency Alert';
  static const String sosMessage = 'Tap to send emergency alert to your contacts and community';
  static const String helpIsOnTheWay = 'Help is on the way!';
  static const String cancelAlert = 'Cancel Alert';

  // Map
  static const String mapTitle = 'Crime Map';
  static const String allCrimes = 'All';
  static const String robbery = 'Robbery';
  static const String theft = 'Theft';
  static const String assault = 'Assault';
  static const String safePlaces = 'Safe Places';

  // Notifications
  static const String notificationsTitle = 'Notifications';
  static const String all = 'All';
  static const String alerts = 'Alerts';
  static const String updates = 'Updates';
  static const String system = 'System';

  // Profile
  static const String profileTitle = 'Profile';
  static const String myReports = 'My Reports';
  static const String settings = 'Settings';
  static const String emergencyContacts = 'Emergency Contacts';
  static const String safetyScoreDetail = 'Safety Score Details';
  static const String savedLocations = 'Saved Locations';
  static const String logout = 'Logout';

  // Common
  static const String loading = 'Loading...';
  static const String error = 'Something went wrong';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String search = 'Search...';
  static const String noData = 'No data available';
}

class OnboardingContent {
  final String title;
  final String description;
  final String icon;

  const OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
  });
}

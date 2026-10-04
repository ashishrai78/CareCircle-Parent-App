/// 📝 CareCircle — Production Text Constants
///
/// All user-facing strings centralized for easy localization and consistency.
/// Replace e-commerce strings with CareCircle (parental monitoring) content.
class UTexts {
  UTexts._();

  // ============ APP INFO ============
  static const String appName = 'CareCircle';
  static const String appTagline = 'Smart Parental Monitoring';
  static const String appDescription =
      'Monitor your child\'s device activity, location, and screen time — all in one place.';

  // ============ ONBOARDING ============
  static const String onBoardingTitle1 = 'Remotely Smart Monitoring';
  static const String onBoardingTitle2 = 'Live Location Tracking';
  static const String onBoardingTitle3 = 'App Activity & Safety';

  static const String onBoardingSubTitle1 =
      'Remotely view device activity. Track location, screen time, and app usage — anytime, anywhere.';
  static const String onBoardingSubTitle2 =
      'Know where your child is in real-time. Get instant updates on their location and movements.';
  static const String onBoardingSubTitle3 =
      'Track installed apps, monitor screen time, and ensure a safe digital environment for your child.';

  static const String skip = 'Skip';
  static const String getStarted = 'Get Started';

  // ============ LOGIN SCREEN ============
  static const String loginTitle = 'Welcome Back 👋';
  static const String loginSubTitle =
      'Log in to monitor your child\'s device and stay connected.';
  static const String email = 'Email';
  static const String emailHint = 'Enter your email address';
  static const String password = 'Password';
  static const String passwordHint = 'Enter your password';
  static const String rememberMe = 'Remember Me';
  static const String forgetPassword = 'Forgot Password?';
  static const String signIn = 'Sign In';
  static const String createAccount = 'Create Account';
  static const String orSignInWith = 'Or Sign In With';

  // ============ SIGNUP SCREEN ============
  static const String signupTitle = 'Let\'s Get You Registered';
  static const String signupSubTitle =
      'Create an account to start monitoring your child\'s device.';
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String phoneNumber = 'Phone Number';
  static const String iAgreeTo = 'I agree to';
  static const String privacyPolicy = 'Privacy Policy';
  static const String and = 'and';
  static const String termsOfUse = 'Terms of Use';
  static const String orSignupWith = 'Or Sign up With';

  // ============ FORGET PASSWORD ============
  static const String forgetPasswordTitle = 'Forgot Password';
  static const String forgetPasswordSubTitle = 'No worries! Enter your registered email address, and we\'ll help you reset your password.';
  static const String submit = 'Submit';

  // ============ RESET PASSWORD ============
  static const String resetPasswordTitle = 'Password Reset Email Sent';
  static const String resetPasswordSubTitle = 'We\'ve sent a password reset link to your email. Please check your inbox and follow the instructions to reset your password.';
  static const String done = 'Done';

  // ============ VERIFY EMAIL ============
  static const String verifyEmailTitle = 'Verify your email address!';
  static const String verifyEmailSubTitle = 'We\'ve sent a verification link to your email. Please check your inbox and click the link to verify your account.';
  static const String uContinue = 'Continue';
  static const String resendEmail = 'Resend Email';

  // ============ ACCOUNT CREATED ============
  static const String accountCreatedTitle = 'Account Successfully Created';
  static const String accountCreatedSubTitle = 'Welcome to CareCircle! Your account has been created. Add your child\'s device to start monitoring.';

  // ============ HOME SCREEN ============
  static const String homeTitle = 'Dashboard';
  static const String homeGreeting = 'Hello, {name} 👋';
  static const String homeSubTitle = 'Here\'s what\'s happening with your children';
  static const String yourChildren = 'Your Children';
  static const String addChild = 'Add Child';
  static const String noChildrenAdded = 'No children added yet';
  static const String noChildrenSubTitle = 'Add your child\'s device to start monitoring their activity.';

  // ============ CHILD CARD ============
  static const String online = 'Online';
  static const String offline = 'Offline';
  static const String lastSeen = 'Last seen {time}';
  static const String viewDetails = 'View Details';
  static const String monitoring = 'Monitoring Active';
  static const String notMonitoring = 'Monitoring Paused';

  // ============ CHILD DETAIL ============
  static const String childDetail = 'Child Details';
  static const String liveLocation = 'Live Location';
  static const String screenTime = 'Screen Time';
  static const String installedApps = 'Installed Apps';
  static const String batteryStatus = 'Battery Status';
  static const String deviceInfo = 'Device Info';
  static const String listenSurroundings = 'Listen to Surroundings';
  static const String requestSync = 'Request Sync';

  // ============ LISTEN SURROUNDINGS ============
  static const String listenTitle = 'Listen to Surroundings';
  static const String listenSubTitle = 'Start a live audio session to hear what\'s happening around your child.';
  static const String startListening = 'Start Listening';
  static const String stopListening = 'Stop Listening';
  static const String listeningActive = 'Listening Active';
  static const String connectingToChild = 'Connecting to child device...';
  static const String listeningWarning = 'This will activate the microphone on your child\'s device. They will see a notification.';

  // ============ SCREEN TIME ============
  static const String todayScreenTime = 'Today\'s Screen Time';
  static const String totalScreenTime = 'Total Screen Time';
  static const String mostUsedApps = 'Most Used Apps';
  static const String hourlyUsage = 'Hourly Usage';
  static const String sessionsToday = 'Sessions Today';
  static const String noUsageData = 'No usage data available';

  // ============ LOCATION ============
  static const String currentLocation = 'Current Location';
  static const String lastUpdated = 'Last updated {time}';
  static const String accuracy = 'Accuracy: ±{meters}m';
  static const String address = 'Address';
  static const String openInMaps = 'Open in Google Maps';
  static const String locationHistory = 'Location History';
  static const String mockLocationDetected = '⚠️ Mock location detected';

  // ============ BATTERY ============
  static const String batteryLevel = 'Battery Level';
  static const String charging = 'Charging';
  static const String notCharging = 'Not Charging';
  static const String batteryTemp = 'Temperature';
  static const String powerSource = 'Power Source';

  // ============ INSTALLED APPS ============
  static const String totalApps = 'Total Apps';
  static const String appCategories = 'Categories';
  static const String lastUpdatedApps = 'Last updated {time}';
  static const String noAppsFound = 'No apps found';

  // ============ ADD CHILD ============
  static const String addChildTitle = 'Add Child Device';
  static const String addChildSubTitle = 'Link your child\'s device to your account using the pairing code.';
  static const String pairingCode = 'Pairing Code';
  static const String pairingCodeHint = 'Enter 6-digit code';
  static const String generateCode = 'Generate Pairing Code';
  static const String scanQRCode = 'Scan QR Code';
  static const String linkDevice = 'Link Device';
  static const String pairingInstructions = 'Open CareCircle Child App on your child\'s device, go to Settings > Link to Parent, and enter this code.';

  // ============ PROFILE ============
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String accountSettings = 'Account Settings';
  static const String notifications = 'Notifications';
  static const String privacy = 'Privacy & Security';
  static const String helpSupport = 'Help & Support';
  static const String about = 'About CareCircle';
  static const String logout = 'Log Out';
  static const String logoutConfirmation = 'Are you sure you want to log out? You\'ll need to sign in again to monitor your children.';

  // ============ ERRORS ============
  static const String errorOccurred = 'An error occurred';
  static const String noInternet = 'No internet connection';
  static const String tryAgain = 'Try Again';
  static const String failedToLoad = 'Failed to load data';
  static const String permissionDenied = 'Permission denied';
  static const String childOffline = 'Child device is offline';
  static const String childOfflineMessage = 'Please ensure your child\'s device is connected to the internet.';

  // ============ SUCCESS ============
  static const String success = 'Success!';
  static const String dataSynced = 'Data synced successfully';
  static const String childAdded = 'Child added successfully';
  static const String settingsUpdated = 'Settings updated successfully';

  // ============ COMMON ============
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String close = 'Close';
  static const String retry = 'Retry';
  static const String loading = 'Loading...';
  static const String refresh = 'Refresh';
  static const String search = 'Search';
  static const String noResults = 'No results found';
  static const String comingSoon = 'Coming Soon';
  static const String minutes = 'min';
  static const String hours = 'hr';
  static const String hoursMinutes = '{hours}h {minutes}m';
}

class AppConfig {
  static const String appName = 'Dream Squad Card Maker';
  static const String packageName = 'com.soikot.dreamsquad';
  static const String versionLabel = '1.1.0';
  static const String privacyPolicyUrl =
      'https://abtachpoint.github.io/dream-squad-card-maker/privacy-policy.html';
  static const String googleServerClientId =
      '553610713446-52poftt47aqmb3ps119bo6ll8pogb42l.apps.googleusercontent.com';

  static const int starterCoins = 40;
  static const int dailyRewardCoins = 10;
  static const int rewardedAdCoins = 5;
  static const int rewardedAdsPerDay = 2;

  static const String admobAppId =
      'ca-app-pub-1379059201302335~9775813971';
  static const String rewardedAdUnitLive =
      'ca-app-pub-1379059201302335/5282035192';
  static const String rewardedAdUnitTest =
      'ca-app-pub-3940256099942544/5224354917';
  static const bool useTestAds =
      bool.fromEnvironment('USE_TEST_ADS', defaultValue: true);

  static const Map<String, int> coinProducts = {
    'coins_100': 100,
    'coins_250': 250,
    'coins_550': 550,
    'coins_1200': 1200,
    'coins_2500': 2500,
  };
}

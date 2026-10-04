import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/card_project.dart';

class AppState extends ChangeNotifier {
  int coins = 40;
  int adCountToday = 0;
  bool loggedIn = false;
  String userName = 'Player';
  String email = 'trial@local';
  String loginMethod = 'Trial';
  String? _rewardDate;
  String? _adDate;
  final List<CardProject> cards = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    coins = p.getInt('coins') ?? 40;
    loggedIn = p.getBool('loggedIn') ?? false;
    userName = p.getString('userName') ?? 'Player';
    email = p.getString('email') ?? 'trial@local';
    loginMethod = p.getString('loginMethod') ?? 'Trial';
    _rewardDate = p.getString('rewardDate');
    _adDate = p.getString('adDate');
    adCountToday = p.getInt('adCountToday') ?? 0;
    final today = _today();
    if (_adDate != today) {
      adCountToday = 0;
      _adDate = today;
      await _persist();
    }
    notifyListeners();
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('coins', coins);
    await p.setBool('loggedIn', loggedIn);
    await p.setString('userName', userName);
    await p.setString('email', email);
    await p.setString('loginMethod', loginMethod);
    if (_rewardDate != null) await p.setString('rewardDate', _rewardDate!);
    if (_adDate != null) await p.setString('adDate', _adDate!);
    await p.setInt('adCountToday', adCountToday);
  }

  Future<void> login({required String name, required String mail, required String method}) async {
    loggedIn = true;
    userName = name;
    email = mail;
    loginMethod = method;
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    loggedIn = false;
    await _persist();
    notifyListeners();
  }

  bool get canClaimDaily => _rewardDate != _today();

  Future<bool> claimDaily() async {
    if (!canClaimDaily) return false;
    coins += 10;
    _rewardDate = _today();
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> rewardAd() async {
    final today = _today();
    if (_adDate != today) {
      adCountToday = 0;
      _adDate = today;
    }
    if (adCountToday >= 2) return false;
    adCountToday += 1;
    coins += 5;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> spend(int value) async {
    if (value <= 0) return true;
    if (coins < value) return false;
    coins -= value;
    await _persist();
    notifyListeners();
    return true;
  }

  void addCard(CardProject card) {
    cards.add(card);
    notifyListeners();
  }

  void deleteCard(CardProject card) {
    cards.remove(card);
    notifyListeners();
  }
}

final appState = AppState();

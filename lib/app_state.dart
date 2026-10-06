import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'data/templates.dart';
import 'models/card_project.dart';
import 'models/coin_history_entry.dart';
import 'models/element_transform.dart';
import 'models/squad_project.dart';

class AppState extends ChangeNotifier {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  GoogleSignIn get _google => GoogleSignIn.instance;

  bool _googleInitialized = false;
  bool _initialized = false;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;

  User? firebaseUser;
  int coins = 0;
  int _adsWatchedStored = 0;
  String? _dailyRewardDate;
  String? _adRewardDate;
  String userName = '';
  String email = '';
  String loginMethod = '';
  String? photoUrl;
  bool accountLoading = true;

  final List<CardProject> cards = [];
  final List<SquadProject> squads = [];
  final List<CoinHistoryEntry> coinHistory = [];

  bool get loggedIn => firebaseUser != null;
  int get adsWatchedToday => _adRewardDate == _today() ? _adsWatchedStored : 0;
  bool get canClaimDaily => _dailyRewardDate != _today();

  Future<void> initialize() async {
    if (_initialized) return;
    await _onAuthChanged(_auth.currentUser);
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user?.uid == firebaseUser?.uid) return;
      unawaited(_onAuthChanged(user));
    });
    _initialized = true;
  }

  Future<void> _onAuthChanged(User? user) async {
    await _userDocSubscription?.cancel();
    _userDocSubscription = null;
    firebaseUser = user;
    cards.clear();
    squads.clear();
    coinHistory.clear();

    if (user == null) {
      coins = 0;
      _adsWatchedStored = 0;
      _dailyRewardDate = null;
      _adRewardDate = null;
      userName = '';
      email = '';
      loginMethod = '';
      photoUrl = null;
      accountLoading = false;
      notifyListeners();
      return;
    }

    accountLoading = true;
    userName = user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : (user.email?.split('@').first ?? 'Player');
    email = user.email ?? '';
    photoUrl = user.photoURL;
    loginMethod = user.providerData.any((p) => p.providerId == 'google.com') ? 'Google' : 'Email';
    notifyListeners();

    try {
      await _ensureUserDocument(user);
      await _loadLocalProjects(user.uid);
      await _refreshCoinHistory();
      _listenUserDocument(user.uid);
    } catch (error, stackTrace) {
      debugPrint('User data initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      // Keep the signed-in session alive even if Firestore is temporarily unavailable.
      await _loadLocalProjects(user.uid);
    } finally {
      accountLoading = false;
      notifyListeners();
    }
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) => _db.collection('users').doc(uid);

  Future<void> _ensureUserDocument(User user) async {
    final ref = _userRef(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': user.displayName ?? user.email?.split('@').first ?? 'Player',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'coins': AppConfig.starterCoins,
        'dailyRewardDate': null,
        'adRewardDate': null,
        'adsWatchedToday': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        'name': user.displayName ?? snap.data()?['name'] ?? 'Player',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  void _listenUserDocument(String uid) {
    _userDocSubscription = _userRef(uid).snapshots().listen(
      (snap) {
        final data = snap.data();
        if (data == null) return;
        coins = (data['coins'] as num?)?.toInt() ?? AppConfig.starterCoins;
        _adsWatchedStored = (data['adsWatchedToday'] as num?)?.toInt() ?? 0;
        _dailyRewardDate = data['dailyRewardDate'] as String?;
        _adRewardDate = data['adRewardDate'] as String?;
        final cloudName = (data['name'] as String?)?.trim();
        if (cloudName != null && cloudName.isNotEmpty) userName = cloudName;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('User data listener failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<UserCredential> signInWithEmail(String mail, String password) =>
      _auth.signInWithEmailAndPassword(email: mail.trim(), password: password);

  Future<UserCredential> signUpWithEmail(String mail, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: mail.trim(), password: password);
    final user = credential.user;
    if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
      await user.updateDisplayName(mail.trim().split('@').first);
    }
    return credential;
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _google.initialize(serverClientId: AppConfig.googleServerClientId);
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(code: 'missing-google-token', message: 'Google sign-in did not return an ID token.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordReset(String mail) => _auth.sendPasswordResetEmail(email: mail.trim());

  Future<void> updateDisplayName(String name) async {
    final user = firebaseUser;
    final clean = name.trim();
    if (user == null || clean.isEmpty) return;
    await user.updateDisplayName(clean);
    await _userRef(user.uid).set({'name': clean, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    userName = clean;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = firebaseUser;
    if (user == null) return;
    final ref = _userRef(user.uid);
    final backup = await ref.get();
    final history = await ref.collection('history').get();
    final processed = await ref.collection('processedPurchases').get();
    for (final doc in [...history.docs, ...processed.docs]) {
      await doc.reference.delete();
    }
    await ref.delete();
    try {
      await user.delete();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cardsKey(user.uid));
      await prefs.remove(_squadsKey(user.uid));
      try {
        await _google.signOut();
      } catch (_) {}
    } catch (e) {
      if (backup.exists && backup.data() != null) {
        await ref.set(backup.data()!);
      }
      rethrow;
    }
  }

  Future<bool> claimDaily() async {
    final user = firebaseUser;
    if (user == null) return false;
    final today = _today();
    final userRef = _userRef(user.uid);
    final historyRef = userRef.collection('history').doc();
    final changed = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? <String, dynamic>{};
      if (data['dailyRewardDate'] == today) return false;
      final current = (data['coins'] as num?)?.toInt() ?? AppConfig.starterCoins;
      tx.set(userRef, {
        'coins': current + AppConfig.dailyRewardCoins,
        'dailyRewardDate': today,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(historyRef, {
        'label': 'Daily Reward',
        'amount': AppConfig.dailyRewardCoins,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (changed) await _refreshCoinHistory();
    return changed;
  }

  Future<bool> creditRewardedAd() async {
    final user = firebaseUser;
    if (user == null) return false;
    final today = _today();
    final userRef = _userRef(user.uid);
    final historyRef = userRef.collection('history').doc();
    final changed = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? <String, dynamic>{};
      final sameDay = data['adRewardDate'] == today;
      final watched = sameDay ? ((data['adsWatchedToday'] as num?)?.toInt() ?? 0) : 0;
      if (watched >= AppConfig.rewardedAdsPerDay) return false;
      final current = (data['coins'] as num?)?.toInt() ?? AppConfig.starterCoins;
      tx.set(userRef, {
        'coins': current + AppConfig.rewardedAdCoins,
        'adRewardDate': today,
        'adsWatchedToday': watched + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(historyRef, {
        'label': 'Rewarded Ad',
        'amount': AppConfig.rewardedAdCoins,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (changed) await _refreshCoinHistory();
    return changed;
  }

  Future<bool> spend(int value, {String label = 'Player Card'}) async {
    if (value <= 0) return true;
    final user = firebaseUser;
    if (user == null) return false;
    final userRef = _userRef(user.uid);
    final historyRef = userRef.collection('history').doc();
    final changed = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(userRef);
      final current = (snap.data()?['coins'] as num?)?.toInt() ?? 0;
      if (current < value) return false;
      tx.update(userRef, {'coins': current - value, 'updatedAt': FieldValue.serverTimestamp()});
      tx.set(historyRef, {
        'label': label,
        'amount': -value,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (changed) await _refreshCoinHistory();
    return changed;
  }

  Future<bool> creditPurchase({required String productId, required String purchaseKey, required int coins}) async {
    final user = firebaseUser;
    if (user == null) return false;
    final userRef = _userRef(user.uid);
    final processedRef = userRef.collection('processedPurchases').doc(purchaseKey);
    final historyRef = userRef.collection('history').doc();
    final changed = await _db.runTransaction<bool>((tx) async {
      final processed = await tx.get(processedRef);
      if (processed.exists) return false;
      final snap = await tx.get(userRef);
      final current = (snap.data()?['coins'] as num?)?.toInt() ?? AppConfig.starterCoins;
      tx.set(processedRef, {
        'productId': productId,
        'coins': coins,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(userRef, {
        'coins': current + coins,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(historyRef, {
        'label': 'Coin Pack +$coins',
        'amount': coins,
        'createdAt': FieldValue.serverTimestamp(),
        'productId': productId,
      });
      return true;
    });
    if (changed) await _refreshCoinHistory();
    return changed;
  }

  Future<void> _refreshCoinHistory() async {
    final user = firebaseUser;
    if (user == null) return;
    try {
      final query = await _userRef(user.uid).collection('history').orderBy('createdAt', descending: true).limit(30).get();
      coinHistory
        ..clear()
        ..addAll(query.docs.map((d) {
          final data = d.data();
          return CoinHistoryEntry(
            label: data['label'] as String? ?? 'Coins',
            amount: (data['amount'] as num?)?.toInt() ?? 0,
            createdAt: data['createdAt'] as Timestamp?,
          );
        }));
      notifyListeners();
    } catch (_) {}
  }

  String _cardsKey(String uid) => 'cardsJson_$uid';
  String _squadsKey(String uid) => 'squadsJson_$uid';

  Future<void> _loadLocalProjects(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    cards.clear();
    squads.clear();

    try {
      final raw = jsonDecode(prefs.getString(_cardsKey(uid)) ?? '[]') as List<dynamic>;
      for (final item in raw.whereType<Map<String, dynamic>>()) {
        final templateId = item['templateId'] as String?;
        final template = cardTemplates.where((e) => e.id == templateId).firstOrNull;
        if (template == null) continue;

        final transformRaw = item['photoTransforms'];
        final opacityRaw = item['photoOpacities'];
        final orderRaw = item['photoOrder'];

        cards.add(CardProject(
          id: item['id'] as String? ?? '',
          template: template,
          playerName: item['playerName'] as String? ?? 'Player',
          rating: (item['rating'] as num?)?.toInt() ?? 90,
          position: item['position'] as String? ?? 'CF',
          previewPath: item['previewPath'] as String? ?? '',
          photoPaths: (item['photoPaths'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e as String?)
              .toList(),
          logoPath: item['logoPath'] as String?,
          flagPath: item['flagPath'] as String?,
          customBackgroundPath: item['customBackgroundPath'] as String?,
          photoTransforms: transformRaw is List
              ? transformRaw.map(ElementTransform.fromJson).toList()
              : const [],
          photoOpacities: opacityRaw is List
              ? opacityRaw.map((e) => ((e as num?)?.toDouble() ?? 1).clamp(0.15, 1.0).toDouble()).toList()
              : const [],
          photoOrder: orderRaw is List
              ? orderRaw.map((e) => (e as num?)?.toInt() ?? 0).toList()
              : const [],
          nameTransform: ElementTransform.fromJson(item['nameTransform']),
          ratingTransform: ElementTransform.fromJson(item['ratingTransform']),
        ));
      }
    } catch (_) {}

    try {
      final raw = jsonDecode(prefs.getString(_squadsKey(uid)) ?? '[]') as List<dynamic>;
      for (final item in raw.whereType<Map<String, dynamic>>()) {
        final playerRaw = item['playerCardIds'];
        final positionRaw = item['playerTransforms'];
        final benchRaw = item['benchCardIds'];
        squads.add(SquadProject(
          id: item['id'] as String? ?? '',
          name: item['name'] as String? ?? 'My Dream Squad',
          formation: item['formation'] as String? ?? '4-3-3',
          previewPath: item['previewPath'] as String? ?? '',
          customFormation: item['customFormation'] as bool? ?? false,
          playerCardIds: playerRaw is List ? playerRaw.map((e) => e as String?).toList() : const [],
          playerTransforms: positionRaw is List
              ? positionRaw.map(ElementTransform.fromJson).toList()
              : const [],
          captainIndex: (item['captainIndex'] as num?)?.toInt(),
          fieldStyle: (item['fieldStyle'] as num?)?.toInt() ?? 0,
          customBackgroundPath: item['customBackgroundPath'] as String?,
          teamLogoPath: item['teamLogoPath'] as String?,
          managerName: item['managerName'] as String? ?? '',
          managerPhotoPath: item['managerPhotoPath'] as String?,
          showBench: item['showBench'] as bool? ?? false,
          benchCardIds: benchRaw is List ? benchRaw.whereType<String>().toList() : const [],
          positionsLocked: item['positionsLocked'] as bool? ?? false,
        ));
      }
    } catch (_) {}
  }

  Future<void> _persistLocalProjects() async {
    final user = firebaseUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _cardsKey(user.uid),
      jsonEncode(
        cards
            .map(
              (c) => {
                'id': c.id,
                'templateId': c.template.id,
                'playerName': c.playerName,
                'rating': c.rating,
                'position': c.position,
                'previewPath': c.previewPath,
                'photoPaths': c.photoPaths,
                'logoPath': c.logoPath,
                'flagPath': c.flagPath,
                'customBackgroundPath': c.customBackgroundPath,
                'photoTransforms': c.photoTransforms.map((e) => e.toJson()).toList(),
                'photoOpacities': c.photoOpacities,
                'photoOrder': c.photoOrder,
                'nameTransform': c.nameTransform.toJson(),
                'ratingTransform': c.ratingTransform.toJson(),
              },
            )
            .toList(),
      ),
    );

    await prefs.setString(
      _squadsKey(user.uid),
      jsonEncode(
        squads
            .map(
              (s) => {
                'id': s.id,
                'name': s.name,
                'formation': s.formation,
                'previewPath': s.previewPath,
                'customFormation': s.customFormation,
                'playerCardIds': s.playerCardIds,
                'playerTransforms': s.playerTransforms.map((e) => e.toJson()).toList(),
                'captainIndex': s.captainIndex,
                'fieldStyle': s.fieldStyle,
                'customBackgroundPath': s.customBackgroundPath,
                'teamLogoPath': s.teamLogoPath,
                'managerName': s.managerName,
                'managerPhotoPath': s.managerPhotoPath,
                'showBench': s.showBench,
                'benchCardIds': s.benchCardIds,
                'positionsLocked': s.positionsLocked,
              },
            )
            .toList(),
      ),
    );
  }

  Future<void> addCard(CardProject card) async {
    cards.add(card);
    await _persistLocalProjects();
    notifyListeners();
  }

  Future<void> updateCard(CardProject card) async {
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index < 0) return;
    cards[index] = card;
    await _persistLocalProjects();
    notifyListeners();
  }

  Future<void> deleteCard(CardProject card) async {
    cards.removeWhere((c) => c.id == card.id);
    await _persistLocalProjects();
    notifyListeners();
  }

  Future<void> duplicateCard(CardProject card) async {
    cards.add(
      CardProject(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        template: card.template,
        playerName: card.playerName,
        rating: card.rating,
        position: card.position,
        previewPath: card.previewPath,
        photoPaths: List<String?>.from(card.photoPaths),
        logoPath: card.logoPath,
        flagPath: card.flagPath,
        customBackgroundPath: card.customBackgroundPath,
        photoTransforms: List<ElementTransform>.from(card.photoTransforms),
        photoOpacities: List<double>.from(card.photoOpacities),
        photoOrder: List<int>.from(card.photoOrder),
        nameTransform: card.nameTransform,
        ratingTransform: card.ratingTransform,
      ),
    );
    await _persistLocalProjects();
    notifyListeners();
  }

  Future<void> addSquad(SquadProject squad) async {
    squads.add(squad);
    await _persistLocalProjects();
    notifyListeners();
  }

  Future<void> updateSquad(SquadProject squad) async {
    final index = squads.indexWhere((s) => s.id == squad.id);
    if (index < 0) return;
    squads[index] = squad;
    await _persistLocalProjects();
    notifyListeners();
  }

  Future<void> deleteSquad(SquadProject squad) async {
    squads.removeWhere((s) => s.id == squad.id);
    await _persistLocalProjects();
    notifyListeners();
  }

  Future<void> duplicateSquad(SquadProject squad) async {
    squads.add(
      SquadProject(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: '${squad.name} Copy',
        formation: squad.formation,
        previewPath: squad.previewPath,
        customFormation: squad.customFormation,
        playerCardIds: List<String?>.from(squad.playerCardIds),
        playerTransforms: List<ElementTransform>.from(squad.playerTransforms),
        captainIndex: squad.captainIndex,
        fieldStyle: squad.fieldStyle,
        customBackgroundPath: squad.customBackgroundPath,
        teamLogoPath: squad.teamLogoPath,
        managerName: squad.managerName,
        managerPhotoPath: squad.managerPhotoPath,
        showBench: squad.showBench,
        benchCardIds: List<String>.from(squad.benchCardIds),
        positionsLocked: squad.positionsLocked,
      ),
    );
    await _persistLocalProjects();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) return item;
    return null;
  }
}

final appState = AppState();

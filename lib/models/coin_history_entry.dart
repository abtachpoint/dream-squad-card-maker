import 'package:cloud_firestore/cloud_firestore.dart';

class CoinHistoryEntry {
  CoinHistoryEntry({required this.label, required this.amount, this.createdAt});
  final String label;
  final int amount;
  final Timestamp? createdAt;
}

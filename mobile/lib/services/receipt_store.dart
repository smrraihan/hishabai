import 'package:flutter/foundation.dart';

import '../models/receipt.dart';
import 'api_service.dart';

class ReceiptStore extends ChangeNotifier {
  ReceiptStore(this.api);

  final ApiService api;
  List<Receipt> receipts = [];
  bool loading = false;
  String? error;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      receipts = await api.list();
    } catch (exception) {
      error = exception.toString().replaceFirst('Bad state: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

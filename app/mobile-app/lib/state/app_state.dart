import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/analysis_record.dart';
import '../models/model_info.dart';
import '../services/api_service.dart';

/// Estado de conexión con el backend.
enum ConnState { unknown, checking, online, offline }

/// Estado central de la aplicación: configuración del servidor, modelo
/// seleccionado, salud del backend e historial de análisis.
class AppState extends ChangeNotifier {
  AppState();

  late SharedPreferences _prefs;

  String _baseUrl = AppConstants.defaultBaseUrl;
  String _model = ModelIds.mobilenet;
  ConnState _conn = ConnState.unknown;
  HealthStatus? _health;
  String? _connError;
  final List<AnalysisRecord> _history = [];

  // --- Getters ---
  String get baseUrl => _baseUrl;
  String get model => _model;
  ConnState get conn => _conn;
  HealthStatus? get health => _health;
  String? get connError => _connError;
  List<AnalysisRecord> get history => List.unmodifiable(_history);

  ApiService get api => ApiService(_baseUrl);

  /// Info del modelo actualmente seleccionado (si /health está disponible).
  ModelInfo? get currentModelInfo {
    final models = _health?.models;
    if (models == null) return null;
    for (final m in models) {
      if (m.name == _model) return m;
    }
    return null;
  }

  /// Carga la configuración persistida y comprueba el backend.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _baseUrl = _prefs.getString(AppConstants.kBaseUrl) ?? _baseUrl;
    _model = _prefs.getString(AppConstants.kModel) ?? _model;

    final rawHistory = _prefs.getString(AppConstants.kHistory);
    if (rawHistory != null && rawHistory.isNotEmpty) {
      try {
        _history
          ..clear()
          ..addAll(AnalysisRecord.decodeList(rawHistory));
      } catch (_) {
        // Historial corrupto: se descarta silenciosamente.
      }
    }
    notifyListeners();
    // Comprobación inicial sin bloquear el arranque.
    refreshHealth();
  }

  // --- Configuración ---
  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    await _prefs.setString(AppConstants.kBaseUrl, _baseUrl);
    notifyListeners();
    await refreshHealth();
  }

  Future<void> setModel(String model) async {
    _model = model;
    await _prefs.setString(AppConstants.kModel, model);
    notifyListeners();
  }

  // --- Salud del backend ---
  Future<void> refreshHealth() async {
    _conn = ConnState.checking;
    _connError = null;
    notifyListeners();
    try {
      final h = await api.health();
      _health = h;
      _conn = ConnState.online;
    } catch (e) {
      _health = null;
      _conn = ConnState.offline;
      _connError = e.toString();
    }
    notifyListeners();
  }

  // --- Historial ---
  Future<void> addRecord(AnalysisRecord record) async {
    _history.insert(0, record);
    // Limita el historial para no crecer indefinidamente en prefs.
    if (_history.length > 40) _history.removeRange(40, _history.length);
    await _persistHistory();
    notifyListeners();
  }

  Future<void> removeRecord(String id) async {
    _history.removeWhere((r) => r.id == id);
    await _persistHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _persistHistory();
    notifyListeners();
  }

  Future<void> _persistHistory() async {
    await _prefs.setString(
        AppConstants.kHistory, AnalysisRecord.encodeList(_history));
  }
}

import 'package:flutter/foundation.dart';
import '../models/promo_template.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final PermissionService _permissionService = PermissionService();

  List<PromoTemplate> _templates = [];
  List<SendHistory> _history = [];
  bool _autoSendEnabled = false;
  bool _permissionsGranted = false;
  bool _isLoading = false;
  int _sendInterval = 0; // 기본값: 매번

  List<PromoTemplate> get templates => _templates;
  List<SendHistory> get history => _history;
  bool get autoSendEnabled => _autoSendEnabled;
  bool get permissionsGranted => _permissionsGranted;
  bool get isLoading => _isLoading;
  int get sendInterval => _sendInterval;

  PromoTemplate? get activeTemplate {
    try {
      return _templates.firstWhere((t) => t.isActive);
    } catch (e) {
      return null;
    }
  }

  // 초기화
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 권한 확인
      _permissionsGranted = await _permissionService.checkPermissions();

      // 데이터 로드
      _templates = await _storageService.getTemplates();
      _history = await _storageService.getHistory();
      _autoSendEnabled = await _storageService.getAutoSendEnabled();
      _sendInterval = await _storageService.getSendInterval();

      // 기본 템플릿이 없으면 샘플 추가
      if (_templates.isEmpty) {
        await _addDefaultTemplate();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('초기화 오류: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 기본 템플릿 추가
  Future<void> _addDefaultTemplate() async {
    final template = PromoTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '샘플 홍보 문구',
      message: '안녕하세요! (주)조유입니다.\n전화 주셔서 감사합니다.\n더 자세한 상담을 원하시면 언제든지 연락 주세요!\n\n상담 문의: 010-XXXX-XXXX',
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _storageService.addTemplate(template);
    _templates = await _storageService.getTemplates();
    notifyListeners();
  }

  // 권한 요청
  Future<bool> requestPermissions() async {
    _permissionsGranted = await _permissionService.requestAllPermissions();
    notifyListeners();
    return _permissionsGranted;
  }

  // 템플릿 관리
  Future<void> addTemplate(PromoTemplate template) async {
    await _storageService.addTemplate(template);
    _templates = await _storageService.getTemplates();
    notifyListeners();
  }

  Future<void> updateTemplate(PromoTemplate template) async {
    await _storageService.updateTemplate(template);
    _templates = await _storageService.getTemplates();
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    await _storageService.deleteTemplate(id);
    _templates = await _storageService.getTemplates();
    notifyListeners();
  }

  Future<void> setActiveTemplate(String id) async {
    await _storageService.setActiveTemplate(id);
    _templates = await _storageService.getTemplates();
    notifyListeners();
  }

  // 자동 발송 토글
  Future<void> toggleAutoSend() async {
    // 권한 확인
    if (!_permissionsGranted) {
      final granted = await requestPermissions();
      if (!granted) {
        return;
      }
    }

    // 활성 템플릿 확인
    if (activeTemplate == null) {
      if (kDebugMode) {
        debugPrint('활성 템플릿이 없습니다');
      }
      return;
    }

    _autoSendEnabled = !_autoSendEnabled;
    await _storageService.setAutoSendEnabled(_autoSendEnabled);
    notifyListeners();
  }

  // 발송 기록
  Future<void> refreshHistory() async {
    _history = await _storageService.getHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _storageService.clearHistory();
    _history = [];
    notifyListeners();
  }

  // 발송 간격 설정
  Future<void> setSendInterval(int days) async {
    _sendInterval = days;
    await _storageService.setSendInterval(days);
    notifyListeners();
  }

  String getSendIntervalText() {
    switch (_sendInterval) {
      case 0:
        return '매번';
      case 7:
        return '1주일';
      case 30:
        return '1개월';
      case 90:
        return '3개월';
      case 180:
        return '6개월';
      default:
        return '$_sendInterval일';
    }
  }

  // 특정 번호로 발송 가능 여부 확인
  Future<bool> canSendToNumber(String phoneNumber) async {
    return await _storageService.canSendToNumber(phoneNumber);
  }

  // 다음 발송 가능 시간
  Future<DateTime?> getNextSendTime(String phoneNumber) async {
    return await _storageService.getNextSendTime(phoneNumber);
  }
}

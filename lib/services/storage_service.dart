import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promo_template.dart';

class StorageService {
  static const String _templatesKey = 'promo_templates';
  static const String _historyKey = 'send_history';
  static const String _enabledKey = 'auto_send_enabled';
  static const String _activeMessageKey = 'promo_message';
  static const String _sendIntervalKey = 'send_interval';
  static const String _lastSendTimesKey = 'last_send_times';

  // 템플릿 관리
  Future<List<PromoTemplate>> getTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_templatesKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => PromoTemplate.fromJson(json)).toList();
  }

  Future<void> saveTemplates(List<PromoTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = templates.map((t) => t.toJson()).toList();
    await prefs.setString(_templatesKey, jsonEncode(jsonList));
    
    // 활성화된 템플릿의 메시지를 네이티브 코드와 공유
    final activeTemplate = templates.firstWhere(
      (t) => t.isActive,
      orElse: () => PromoTemplate(
        id: '',
        title: '',
        message: '',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    );
    
    await prefs.setString(_activeMessageKey, activeTemplate.message);
  }

  Future<void> addTemplate(PromoTemplate template) async {
    final templates = await getTemplates();
    templates.add(template);
    await saveTemplates(templates);
  }

  Future<void> updateTemplate(PromoTemplate template) async {
    final templates = await getTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);
    
    if (index != -1) {
      templates[index] = template;
      await saveTemplates(templates);
    }
  }

  Future<void> deleteTemplate(String id) async {
    final templates = await getTemplates();
    templates.removeWhere((t) => t.id == id);
    await saveTemplates(templates);
  }

  Future<void> setActiveTemplate(String id) async {
    final templates = await getTemplates();
    
    for (var i = 0; i < templates.length; i++) {
      templates[i] = templates[i].copyWith(isActive: templates[i].id == id);
    }
    
    await saveTemplates(templates);
  }

  // 자동 발송 설정
  Future<bool> getAutoSendEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setAutoSendEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  // 발송 기록 관리
  Future<List<SendHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    
    if (historyJson == null) return [];
    
    try {
      final List<dynamic> historyList = jsonDecode(historyJson);
      final List<SendHistory> history = historyList
          .map((json) => SendHistory.fromJson(json))
          .toList();
      
      // 최신순 정렬
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return history;
    } catch (e) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // 발송 간격 설정 (일 단위: 0=매번, 7=1주일, 30=1개월, 90=3개월, 180=6개월)
  Future<int> getSendInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sendIntervalKey) ?? 0; // 기본값: 매번
  }

  Future<void> setSendInterval(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sendIntervalKey, days);
  }

  // 마지막 발송 시간 관리 (전화번호별)
  Future<Map<String, int>> getLastSendTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_lastSendTimesKey);
    
    if (jsonString == null) return {};
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  Future<void> updateLastSendTime(String phoneNumber, int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSendTimes = await getLastSendTimes();
    
    lastSendTimes[phoneNumber] = timestamp;
    
    await prefs.setString(_lastSendTimesKey, jsonEncode(lastSendTimes));
  }

  Future<bool> canSendToNumber(String phoneNumber) async {
    final interval = await getSendInterval();
    
    // 매번 발송
    if (interval == 0) return true;
    
    final lastSendTimes = await getLastSendTimes();
    final lastSendTime = lastSendTimes[phoneNumber];
    
    // 이 번호로 발송한 적 없음
    if (lastSendTime == null) return true;
    
    // 마지막 발송 시간과 비교
    final now = DateTime.now().millisecondsSinceEpoch;
    final intervalMs = interval * 24 * 60 * 60 * 1000; // 일 -> 밀리초
    
    return (now - lastSendTime) >= intervalMs;
  }

  Future<DateTime?> getNextSendTime(String phoneNumber) async {
    final interval = await getSendInterval();
    
    // 매번 발송이면 null 반환
    if (interval == 0) return null;
    
    final lastSendTimes = await getLastSendTimes();
    final lastSendTime = lastSendTimes[phoneNumber];
    
    // 발송한 적 없으면 null
    if (lastSendTime == null) return null;
    
    final nextTime = lastSendTime + (interval * 24 * 60 * 60 * 1000);
    return DateTime.fromMillisecondsSinceEpoch(nextTime);
  }

  // 광고가 포함된 활성 메시지를 SharedPreferences에 저장
  Future<void> updateActiveMessageWithAd(String messageWithAd) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeMessageKey, messageWithAd);
  }
}

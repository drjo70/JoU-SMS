package com.joyou.autopromosms.auto_promo_sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.telephony.SmsManager
import android.util.Log

class PhoneCallReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "PhoneCallReceiver"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_ENABLED = "flutter.auto_send_enabled"
        private const val KEY_MESSAGE = "flutter.promo_message"
        private const val KEY_SEND_INTERVAL = "flutter.send_interval"
        private const val KEY_LAST_SEND_TIMES = "flutter.last_send_times"
        private const val KEY_LAST_INCOMING_NUMBER = "flutter.last_incoming_number"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        try {
            Log.d(TAG, "========================================")
            LogManager.d(TAG, "========================================")
            Log.d(TAG, "📞 PhoneCallReceiver 실행됨!")
            LogManager.d(TAG, "📞 PhoneCallReceiver 실행됨!")
            
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            Log.d(TAG, "전화 상태: $state")
            LogManager.d(TAG, "전화 상태: $state")
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            // RINGING: 전화번호 저장
            if (state == TelephonyManager.EXTRA_STATE_RINGING) {
                val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                Log.d(TAG, "🔔 전화 수신 (RINGING): $incomingNumber")
                LogManager.i(TAG, "🔔 전화 수신 (RINGING): $incomingNumber")
                
                // 전화번호 저장 (OFFHOOK에서 사용)
                if (!incomingNumber.isNullOrEmpty()) {
                    prefs.edit().putString(KEY_LAST_INCOMING_NUMBER, incomingNumber).apply()
                    Log.d(TAG, "전화번호 저장: $incomingNumber")
                    LogManager.d(TAG, "전화번호 저장: $incomingNumber")
                }
            }
            
            // OFFHOOK: 전화 받은 후 SMS 발송
            else if (state == TelephonyManager.EXTRA_STATE_OFFHOOK) {
                Log.d(TAG, "📱 전화 연결됨 (OFFHOOK) - SMS 발송 시작")
                LogManager.i(TAG, "📱 전화 연결됨 (OFFHOOK) - SMS 발송 시작")
                
                // 저장된 전화번호 가져오기
                val incomingNumber = prefs.getString(KEY_LAST_INCOMING_NUMBER, null)
                
                if (incomingNumber.isNullOrEmpty()) {
                    Log.e(TAG, "❌ 저장된 전화번호 없음")
                    LogManager.e(TAG, "❌ 저장된 전화번호 없음")
                    Log.d(TAG, "========================================")
                    LogManager.d(TAG, "========================================")
                    return
                }
                
                Log.d(TAG, "📞 발송 대상 번호: $incomingNumber")
                LogManager.i(TAG, "📞 발송 대상 번호: $incomingNumber")
                
                // SharedPreferences에서 설정 읽기
                val isEnabled = prefs.getBoolean(KEY_ENABLED, false)
                val message = prefs.getString(KEY_MESSAGE, "") ?: ""
                
                Log.d(TAG, "자동발송 활성화: $isEnabled")
                LogManager.d(TAG, "자동발송 활성화: $isEnabled")
                Log.d(TAG, "메시지 존재: ${message.isNotEmpty()}")
                LogManager.d(TAG, "메시지 존재: ${message.isNotEmpty()}")
                Log.d(TAG, "메시지 내용: ${if (message.length > 50) message.substring(0, 50) + "..." else message}")
                LogManager.d(TAG, "메시지 내용: ${if (message.length > 50) message.substring(0, 50) + "..." else message}")
                Log.d(TAG, "전화번호 존재: ${!incomingNumber.isNullOrEmpty()}")
                LogManager.d(TAG, "전화번호 존재: ${!incomingNumber.isNullOrEmpty()}")
                
                if (isEnabled && message.isNotEmpty() && !incomingNumber.isNullOrEmpty()) {
                    Log.d(TAG, "✅ 모든 조건 통과! 발송 간격 체크 중...")
                    LogManager.i(TAG, "✅ 모든 조건 통과! 발송 간격 체크 중...")
                    
                    // 발송 가능 여부 체크 (간격 확인)
                    if (canSendToNumber(prefs, incomingNumber)) {
                        Log.d(TAG, "🚀 SMS 발송 시작: $incomingNumber")
                        LogManager.i(TAG, "🚀 SMS 발송 시작: $incomingNumber")
                        
                        // SMS 발송
                        sendSMS(incomingNumber, message, context)
                        
                        // 발송 기록 저장
                        saveSendHistory(context, incomingNumber, message)
                        
                        // 마지막 발송 시간 업데이트
                        updateLastSendTime(prefs, incomingNumber)
                        
                        Log.d(TAG, "✅ SMS 발송 완료: $incomingNumber")
                        LogManager.i(TAG, "✅ SMS 발송 완료: $incomingNumber")
                    } else {
                        Log.d(TAG, "⏳ 발송 간격 제한으로 스킵: $incomingNumber")
                        LogManager.w(TAG, "⏳ 발송 간격 제한으로 스킵: $incomingNumber")
                    }
                } else {
                    Log.e(TAG, "❌ 발송 조건 미충족!")
                    LogManager.e(TAG, "❌ 발송 조건 미충족!")
                    if (!isEnabled) {
                        Log.e(TAG, "  - 자동발송이 비활성화됨")
                        LogManager.e(TAG, "  - 자동발송이 비활성화됨")
                    }
                    if (message.isEmpty()) {
                        Log.e(TAG, "  - 메시지가 비어있음")
                        LogManager.e(TAG, "  - 메시지가 비어있음")
                    }
                    if (incomingNumber.isNullOrEmpty()) {
                        Log.e(TAG, "  - 전화번호가 없음")
                        LogManager.e(TAG, "  - 전화번호가 없음")
                    }
                }
            } else {
                Log.d(TAG, "전화 수신 상태 아님 (상태: $state)")
                LogManager.d(TAG, "전화 수신 상태 아님 (상태: $state)")
            }
            Log.d(TAG, "========================================")
            LogManager.d(TAG, "========================================")
        } catch (e: Exception) {
            Log.e(TAG, "❌❌❌ 치명적 오류 발생: ${e.message}", e)
            LogManager.e(TAG, "❌❌❌ 치명적 오류 발생: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private fun sendSMS(phoneNumber: String, message: String, context: Context) {
        try {
            Log.d(TAG, "📤 SMS 발송 시작...")
            Log.d(TAG, "  대상: $phoneNumber")
            Log.d(TAG, "  메시지 길이: ${message.length}자")
            
            val smsManager = SmsManager.getDefault()
            
            // 메시지가 길 경우 분할 발송
            val parts = smsManager.divideMessage(message)
            Log.d(TAG, "  분할 메시지: ${parts.size}개")
            
            if (parts.size > 1) {
                Log.d(TAG, "  멀티파트 SMS 발송 중...")
                smsManager.sendMultipartTextMessage(
                    phoneNumber,
                    null,
                    parts,
                    null,
                    null
                )
            } else {
                Log.d(TAG, "  단일 SMS 발송 중...")
                smsManager.sendTextMessage(
                    phoneNumber,
                    null,
                    message,
                    null,
                    null
                )
            }
            
            Log.d(TAG, "✅ SMS 발송 API 호출 완료: $phoneNumber")
        } catch (e: Exception) {
            Log.e(TAG, "❌ SMS 발송 실패: ${e.message}", e)
            e.printStackTrace()
        }
    }
    
    private fun saveSendHistory(context: Context, phoneNumber: String, message: String) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val historyJson = prefs.getString("flutter.history", "[]") ?: "[]"
            
            // JSON 파싱
            val historyList = org.json.JSONArray(historyJson)
            
            // 새 기록 추가
            val timestamp = System.currentTimeMillis()
            val newRecord = org.json.JSONObject()
            newRecord.put("phoneNumber", phoneNumber)
            newRecord.put("message", message)
            newRecord.put("timestamp", timestamp)
            
            historyList.put(newRecord)
            
            // 최대 100개까지만 저장
            val trimmedList = org.json.JSONArray()
            val startIndex = if (historyList.length() > 100) historyList.length() - 100 else 0
            for (i in startIndex until historyList.length()) {
                trimmedList.put(historyList.get(i))
            }
            
            prefs.edit().putString("flutter.history", trimmedList.toString()).apply()
            
            Log.d(TAG, "발송 기록 저장 완료")
        } catch (e: Exception) {
            Log.e(TAG, "기록 저장 실패: ${e.message}", e)
        }
    }
    
    private fun canSendToNumber(prefs: android.content.SharedPreferences, phoneNumber: String): Boolean {
        try {
            // 발송 간격 설정 읽기 (일 단위)
            val intervalDays = prefs.getInt(KEY_SEND_INTERVAL, 0)
            Log.d(TAG, "발송 간격 설정: ${intervalDays}일")
            
            // 매번 발송 설정
            if (intervalDays == 0) {
                Log.d(TAG, "✅ 매번 발송 모드 - 발송 가능")
                return true
            }
            
            // 마지막 발송 시간 읽기
            val lastSendTimesJson = prefs.getString(KEY_LAST_SEND_TIMES, "{}") ?: "{}"
            val lastSendTimes = org.json.JSONObject(lastSendTimesJson)
            
            // 이 번호로 발송한 적 없음
            if (!lastSendTimes.has(phoneNumber)) return true
            
            // 마지막 발송 시간과 비교
            val lastSendTime = lastSendTimes.getLong(phoneNumber)
            val now = System.currentTimeMillis()
            val intervalMs = intervalDays * 24 * 60 * 60 * 1000L // 일 -> 밀리초
            
            val canSend = (now - lastSendTime) >= intervalMs
            
            if (!canSend) {
                val remainingDays = ((intervalMs - (now - lastSendTime)) / (24 * 60 * 60 * 1000L)).toInt() + 1
                Log.d(TAG, "발송 제한: $phoneNumber (남은 기간: ${remainingDays}일)")
            }
            
            return canSend
        } catch (e: Exception) {
            Log.e(TAG, "발송 가능 체크 오류: ${e.message}", e)
            return true // 오류 시 발송 허용
        }
    }
    
    private fun updateLastSendTime(prefs: android.content.SharedPreferences, phoneNumber: String) {
        try {
            val lastSendTimesJson = prefs.getString(KEY_LAST_SEND_TIMES, "{}") ?: "{}"
            val lastSendTimes = org.json.JSONObject(lastSendTimesJson)
            
            // 현재 시간 저장
            lastSendTimes.put(phoneNumber, System.currentTimeMillis())
            
            prefs.edit().putString(KEY_LAST_SEND_TIMES, lastSendTimes.toString()).apply()
            
            Log.d(TAG, "마지막 발송 시간 업데이트: $phoneNumber")
        } catch (e: Exception) {
            Log.e(TAG, "발송 시간 업데이트 실패: ${e.message}", e)
        }
    }
}

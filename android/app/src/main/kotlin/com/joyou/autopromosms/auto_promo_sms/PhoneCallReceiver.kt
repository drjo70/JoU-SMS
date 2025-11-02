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
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            
            // 전화 수신 상태 확인
            if (state == TelephonyManager.EXTRA_STATE_RINGING) {
                val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                
                Log.d(TAG, "전화 수신: $incomingNumber")
                
                // SharedPreferences에서 설정 읽기
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val isEnabled = prefs.getBoolean(KEY_ENABLED, false)
                val message = prefs.getString(KEY_MESSAGE, "") ?: ""
                
                if (isEnabled && message.isNotEmpty() && !incomingNumber.isNullOrEmpty()) {
                    // 발송 가능 여부 체크 (간격 확인)
                    if (canSendToNumber(prefs, incomingNumber)) {
                        // SMS 발송
                        sendSMS(incomingNumber, message, context)
                        
                        // 발송 기록 저장
                        saveSendHistory(context, incomingNumber, message)
                        
                        // 마지막 발송 시간 업데이트
                        updateLastSendTime(prefs, incomingNumber)
                        
                        Log.d(TAG, "SMS 발송 완료: $incomingNumber")
                    } else {
                        Log.d(TAG, "발송 간격 제한으로 스킵: $incomingNumber")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "오류 발생: ${e.message}", e)
        }
    }
    
    private fun sendSMS(phoneNumber: String, message: String, context: Context) {
        try {
            val smsManager = SmsManager.getDefault()
            
            // 메시지가 길 경우 분할 발송
            val parts = smsManager.divideMessage(message)
            
            if (parts.size > 1) {
                smsManager.sendMultipartTextMessage(
                    phoneNumber,
                    null,
                    parts,
                    null,
                    null
                )
            } else {
                smsManager.sendTextMessage(
                    phoneNumber,
                    null,
                    message,
                    null,
                    null
                )
            }
            
            Log.d(TAG, "SMS 발송 완료: $phoneNumber")
        } catch (e: Exception) {
            Log.e(TAG, "SMS 발송 실패: ${e.message}", e)
        }
    }
    
    private fun saveSendHistory(context: Context, phoneNumber: String, message: String) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val historyJson = prefs.getString("send_history", "[]") ?: "[]"
            
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
            
            prefs.edit().putString("send_history", trimmedList.toString()).apply()
            
            Log.d(TAG, "발송 기록 저장 완료")
        } catch (e: Exception) {
            Log.e(TAG, "기록 저장 실패: ${e.message}", e)
        }
    }
    
    private fun canSendToNumber(prefs: android.content.SharedPreferences, phoneNumber: String): Boolean {
        try {
            // 발송 간격 설정 읽기 (일 단위)
            val intervalDays = prefs.getInt(KEY_SEND_INTERVAL, 0)
            
            // 매번 발송 설정
            if (intervalDays == 0) return true
            
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

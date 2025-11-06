package com.joyou.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.telephony.SmsManager
import android.database.Cursor
import android.provider.CallLog
import android.util.Log

class PhoneCallReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "PhoneCallReceiver"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_ENABLED = "flutter.auto_send_enabled"
        private const val KEY_MESSAGE = "flutter.message"
        
        private var lastState = TelephonyManager.CALL_STATE_IDLE
        private var isIncoming = false
        private var savedNumber: String? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

        Log.d(TAG, "📞 [v0.2.1] 전화 상태 변경: $state")

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                isIncoming = true
                savedNumber = number
                Log.d(TAG, "📲 [v0.1.2] 전화 수신 중: $number")
                Log.d(TAG, "  - isIncoming = true")
                Log.d(TAG, "  - savedNumber = $number")
            }
            
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                Log.d(TAG, "☎️ [v0.1.2] 통화 시작")
                Log.d(TAG, "  - isIncoming = $isIncoming")
            }
            
            TelephonyManager.EXTRA_STATE_IDLE -> {
                Log.d(TAG, "🔚 [v0.1.2] IDLE 상태 (전화 종료)")
                Log.d(TAG, "  - lastState = $lastState")
                Log.d(TAG, "  - isIncoming = $isIncoming")
                
                // OFFHOOK에서 IDLE로 변경 && 수신 전화였다면
                if (lastState == TelephonyManager.CALL_STATE_OFFHOOK && isIncoming) {
                    Log.d(TAG, "✅ [v0.1.2] 통화 종료 감지 - SMS 발송 시도")
                    
                    // 전화번호 가져오기
                    val phoneNumber = savedNumber ?: getLastIncomingNumber(context)
                    
                    if (phoneNumber != null) {
                        Log.d(TAG, "📱 [v0.1.2] 전화번호: $phoneNumber")
                        sendSms(context, phoneNumber)
                    } else {
                        Log.d(TAG, "❌ [v0.1.2] 전화번호 없음")
                    }
                } else {
                    Log.d(TAG, "⏭️ [v0.1.2] SMS 발송 조건 미충족")
                    Log.d(TAG, "  - lastState == OFFHOOK? ${lastState == TelephonyManager.CALL_STATE_OFFHOOK}")
                    Log.d(TAG, "  - isIncoming? $isIncoming")
                }
                
                // 상태 초기화 (중요!)
                isIncoming = false
                savedNumber = null
                Log.d(TAG, "🔄 [v0.1.2] 상태 초기화 완료 (다음 전화 대기)")
            }
        }

        lastState = when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> TelephonyManager.CALL_STATE_RINGING
            TelephonyManager.EXTRA_STATE_OFFHOOK -> TelephonyManager.CALL_STATE_OFFHOOK
            else -> TelephonyManager.CALL_STATE_IDLE
        }
    }

    private fun getLastIncomingNumber(context: Context): String? {
        Log.d(TAG, "🔍 [v0.1] CallLog에서 최근 통화 번호 조회...")
        
        try {
            val cursor: Cursor? = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.NUMBER),
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val numberIndex = it.getColumnIndex(CallLog.Calls.NUMBER)
                    if (numberIndex >= 0) {
                        val number = it.getString(numberIndex)
                        Log.d(TAG, "✅ [v0.1] CallLog 번호 찾음: $number")
                        return number
                    }
                }
            }
        } catch (e: Exception) {
            Log.d(TAG, "❌ [v0.1] CallLog 조회 실패: ${e.message}")
        }
        
        return null
    }

    private fun sendSms(context: Context, phoneNumber: String) {
        try {
            Log.d(TAG, "🔧 [v0.1] sendSms() 시작!")
            Log.d(TAG, "  - 받는 사람: $phoneNumber")
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            Log.d(TAG, "📂 [v0.1] SharedPreferences 파일 확인:")
            Log.d(TAG, "  - 파일명: $PREFS_NAME")
            Log.d(TAG, "  - 키(자동발송): $KEY_ENABLED")
            Log.d(TAG, "  - 키(메시지): $KEY_MESSAGE")
            
            // 모든 키 출력
            val allKeys = prefs.all.keys.joinToString(", ")
            Log.d(TAG, "🔑 [v0.1] 저장된 모든 키: $allKeys")
            
            // 설정 확인
            val enabled = prefs.getBoolean(KEY_ENABLED, false)
            val message = prefs.getString(KEY_MESSAGE, null)
            
            Log.d(TAG, "⚙️ [v0.1] 설정 값 확인:")
            Log.d(TAG, "  - 자동발송($KEY_ENABLED): $enabled")
            Log.d(TAG, "  - 메시지 존재: ${message != null}")
            if (message != null) {
                Log.d(TAG, "  - 메시지 내용: $message")
                Log.d(TAG, "  - 메시지 길이: ${message.length}자")
            }
            
            if (!enabled) {
                Log.d(TAG, "⏸️⏸️⏸️ [v0.1] 자동발송이 꺼져있습니다!")
                Log.d(TAG, "  - KEY_ENABLED = false")
                Log.d(TAG, "  - SMS 발송하지 않음")
                return
            }
            
            if (message.isNullOrEmpty()) {
                Log.d(TAG, "❌❌❌ [v0.1] 메시지가 비어있습니다!")
                Log.d(TAG, "  - KEY_MESSAGE = null or empty")
                Log.d(TAG, "  - SMS 발송하지 않음")
                return
            }
            
            // SMS 발송
            Log.d(TAG, "🚀🚀🚀 [v0.1] SMS 발송 시도!")
            Log.d(TAG, "  - 받는 사람: $phoneNumber")
            Log.d(TAG, "  - 메시지: $message")
            
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            
            Log.d(TAG, "✅✅✅ [v0.1] SMS 발송 완료!")
            
        } catch (e: Exception) {
            Log.d(TAG, "❌❌❌ [v0.1] SMS 발송 실패!")
            Log.d(TAG, "  - 오류: ${e.message}")
            Log.d(TAG, "  - 스택: ${e.stackTraceToString()}")
        }
    }
}

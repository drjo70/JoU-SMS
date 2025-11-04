package com.joyou.autopromosms.auto_promo_sms

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

        print("📞 [v0.1] 전화 상태 변경: $state")

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                isIncoming = true
                savedNumber = number
                print("📲 [v0.1.2] 전화 수신 중: $number")
                print("  - isIncoming = true")
                print("  - savedNumber = $number")
            }
            
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                print("☎️ [v0.1.2] 통화 시작")
                print("  - isIncoming = $isIncoming")
            }
            
            TelephonyManager.EXTRA_STATE_IDLE -> {
                print("🔚 [v0.1.2] IDLE 상태 (전화 종료)")
                print("  - lastState = $lastState")
                print("  - isIncoming = $isIncoming")
                
                // OFFHOOK에서 IDLE로 변경 && 수신 전화였다면
                if (lastState == TelephonyManager.CALL_STATE_OFFHOOK && isIncoming) {
                    print("✅ [v0.1.2] 통화 종료 감지 - SMS 발송 시도")
                    
                    // 전화번호 가져오기
                    val phoneNumber = savedNumber ?: getLastIncomingNumber(context)
                    
                    if (phoneNumber != null) {
                        print("📱 [v0.1.2] 전화번호: $phoneNumber")
                        sendSms(context, phoneNumber)
                    } else {
                        print("❌ [v0.1.2] 전화번호 없음")
                    }
                } else {
                    print("⏭️ [v0.1.2] SMS 발송 조건 미충족")
                    print("  - lastState == OFFHOOK? ${lastState == TelephonyManager.CALL_STATE_OFFHOOK}")
                    print("  - isIncoming? $isIncoming")
                }
                
                // 상태 초기화 (중요!)
                isIncoming = false
                savedNumber = null
                print("🔄 [v0.1.2] 상태 초기화 완료 (다음 전화 대기)")
            }
        }

        lastState = when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> TelephonyManager.CALL_STATE_RINGING
            TelephonyManager.EXTRA_STATE_OFFHOOK -> TelephonyManager.CALL_STATE_OFFHOOK
            else -> TelephonyManager.CALL_STATE_IDLE
        }
    }

    private fun getLastIncomingNumber(context: Context): String? {
        print("🔍 [v0.1] CallLog에서 최근 통화 번호 조회...")
        
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
                        print("✅ [v0.1] CallLog 번호 찾음: $number")
                        return number
                    }
                }
            }
        } catch (e: Exception) {
            print("❌ [v0.1] CallLog 조회 실패: ${e.message}")
        }
        
        return null
    }

    private fun sendSms(context: Context, phoneNumber: String) {
        try {
            print("🔧 [v0.1] sendSms() 시작!")
            print("  - 받는 사람: $phoneNumber")
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            print("📂 [v0.1] SharedPreferences 파일 확인:")
            print("  - 파일명: $PREFS_NAME")
            print("  - 키(자동발송): $KEY_ENABLED")
            print("  - 키(메시지): $KEY_MESSAGE")
            
            // 모든 키 출력
            val allKeys = prefs.all.keys.joinToString(", ")
            print("🔑 [v0.1] 저장된 모든 키: $allKeys")
            
            // 설정 확인
            val enabled = prefs.getBoolean(KEY_ENABLED, false)
            val message = prefs.getString(KEY_MESSAGE, null)
            
            print("⚙️ [v0.1] 설정 값 확인:")
            print("  - 자동발송($KEY_ENABLED): $enabled")
            print("  - 메시지 존재: ${message != null}")
            if (message != null) {
                print("  - 메시지 내용: $message")
                print("  - 메시지 길이: ${message.length}자")
            }
            
            if (!enabled) {
                print("⏸️⏸️⏸️ [v0.1] 자동발송이 꺼져있습니다!")
                print("  - KEY_ENABLED = false")
                print("  - SMS 발송하지 않음")
                return
            }
            
            if (message.isNullOrEmpty()) {
                print("❌❌❌ [v0.1] 메시지가 비어있습니다!")
                print("  - KEY_MESSAGE = null or empty")
                print("  - SMS 발송하지 않음")
                return
            }
            
            // SMS 발송
            print("🚀🚀🚀 [v0.1] SMS 발송 시도!")
            print("  - 받는 사람: $phoneNumber")
            print("  - 메시지: $message")
            
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            
            print("✅✅✅ [v0.1] SMS 발송 완료!")
            
        } catch (e: Exception) {
            print("❌❌❌ [v0.1] SMS 발송 실패!")
            print("  - 오류: ${e.message}")
            print("  - 스택: ${e.stackTraceToString()}")
        }
    }
}

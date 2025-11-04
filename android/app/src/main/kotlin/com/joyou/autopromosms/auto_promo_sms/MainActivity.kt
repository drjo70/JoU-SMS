package com.joyou.autopromosms.auto_promo_sms

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.joyou.autopromosms/logs"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // MethodChannel 설정
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRecentLogs" -> {
                        // 최근 로그를 포맷된 문자열로 반환
                        val count = call.argument<Int>("count") ?: 100
                        val logs = LogManager.getRecentLogsFormatted(count)
                        result.success(logs)
                    }
                    "clearLogs" -> {
                        // 모든 로그 삭제
                        LogManager.clear()
                        result.success("로그가 초기화되었습니다.")
                    }
                    "getLogCount" -> {
                        // 현재 로그 개수 반환
                        val count = LogManager.size()
                        result.success(count)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
        
        // 앱 시작 로그
        LogManager.i("MainActivity", "앱이 시작되었습니다.")
        LogManager.i("MainActivity", "로그 뷰어 준비 완료")
    }
}

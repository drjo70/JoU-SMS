package com.joyou.sms

import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.joyou.sms/phone"
    private lateinit var phoneCallReceiver: PhoneCallReceiver
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // MethodChannel 설정
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "registerReceiver" -> {
                    registerPhoneReceiver()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // BroadcastReceiver 자동 등록
        registerPhoneReceiver()
    }
    
    private fun registerPhoneReceiver() {
        phoneCallReceiver = PhoneCallReceiver()
        val filter = IntentFilter()
        filter.addAction("android.intent.action.PHONE_STATE")
        filter.priority = 999
        registerReceiver(phoneCallReceiver, filter)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(phoneCallReceiver)
        } catch (e: Exception) {
            // Already unregistered
        }
    }
}

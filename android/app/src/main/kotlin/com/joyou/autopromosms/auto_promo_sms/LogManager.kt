package com.joyou.autopromosms.auto_promo_sms

import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * 앱 내부 로그를 메모리에 저장하고 관리하는 싱글톤 클래스
 * PhoneCallReceiver의 동작을 실시간으로 추적하기 위함
 */
object LogManager {
    private val logs = ConcurrentLinkedQueue<LogEntry>()
    private const val MAX_LOGS = 500 // 최대 로그 개수
    
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.getDefault())
    
    data class LogEntry(
        val timestamp: Long,
        val level: String,
        val tag: String,
        val message: String
    ) {
        fun toFormattedString(): String {
            val timeStr = dateFormat.format(Date(timestamp))
            return "[$level] $timeStr [$tag] $message"
        }
    }
    
    /**
     * 로그 추가
     */
    fun log(level: String, tag: String, message: String) {
        val entry = LogEntry(
            timestamp = System.currentTimeMillis(),
            level = level,
            tag = tag,
            message = message
        )
        
        logs.add(entry)
        
        // 최대 개수 초과 시 오래된 로그 삭제
        while (logs.size > MAX_LOGS) {
            logs.poll()
        }
    }
    
    /**
     * DEBUG 레벨 로그
     */
    fun d(tag: String, message: String) {
        log("DEBUG", tag, message)
    }
    
    /**
     * INFO 레벨 로그
     */
    fun i(tag: String, message: String) {
        log("INFO", tag, message)
    }
    
    /**
     * WARNING 레벨 로그
     */
    fun w(tag: String, message: String) {
        log("WARN", tag, message)
    }
    
    /**
     * ERROR 레벨 로그
     */
    fun e(tag: String, message: String) {
        log("ERROR", tag, message)
    }
    
    /**
     * 최근 N개의 로그 가져오기
     */
    fun getRecentLogs(count: Int = 100): List<LogEntry> {
        return logs.toList().takeLast(count)
    }
    
    /**
     * 최근 로그를 포맷된 문자열로 가져오기
     */
    fun getRecentLogsFormatted(count: Int = 100): String {
        val recentLogs = getRecentLogs(count)
        return if (recentLogs.isEmpty()) {
            "아직 로그가 없습니다.\n전화를 수신하면 여기에 로그가 표시됩니다."
        } else {
            recentLogs.joinToString("\n") { it.toFormattedString() }
        }
    }
    
    /**
     * 특정 시간 이후의 로그만 가져오기
     */
    fun getLogsSince(timestamp: Long): List<LogEntry> {
        return logs.filter { it.timestamp > timestamp }
    }
    
    /**
     * 모든 로그 삭제
     */
    fun clear() {
        logs.clear()
        log("INFO", "LogManager", "로그가 초기화되었습니다.")
    }
    
    /**
     * 현재 로그 개수
     */
    fun size(): Int {
        return logs.size
    }
}

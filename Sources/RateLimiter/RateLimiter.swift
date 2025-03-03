//
//  File.swift
//  coenttb-web
//
//  Created by Coen ten Thije Boonkkamp on 19/12/2024.
//

import Foundation
import BoundedCache
import Dependencies


/// A generic rate limiter that can be used for various rate limiting scenarios
public actor RateLimiter<Key: Hashable & Sendable> {
    
    public struct WindowConfig: Sendable {
        let duration: TimeInterval
        let maxAttempts: Int
        
        public static func minutes(_ minutes: Int, maxAttempts: Int) -> WindowConfig {
            WindowConfig(duration: TimeInterval(minutes * 60), maxAttempts: maxAttempts)
        }
        
        public static func hours(_ hours: Int, maxAttempts: Int) -> WindowConfig {
            WindowConfig(duration: TimeInterval(hours * 3600), maxAttempts: maxAttempts)
        }
    }
    
    struct AttemptInfo: Sendable {
        let windowStart: Date
        var attempts: Int
        var consecutiveFailures: Int
        let timestamp: Date
    }
    
    public struct RateLimitResult: Sendable {
        public let isAllowed: Bool
        public let currentAttempts: Int
        public let remainingAttempts: Int
        public let nextAllowedAttempt: Date?
        public let backoffInterval: TimeInterval?
    }
    
    private let windows: [WindowConfig]
    private let maxCacheSize: Int
    private let backoffMultiplier: Double
    private var attemptsByKey: BoundedCache<Key, [AttemptInfo]>
    private let metricsCallback: ((Key, RateLimitResult) async -> Void)?
    
    /// Initializes a new rate limiter with the specified configuration.
    ///
    /// - Parameters:
    ///   - windows: An array of window configurations that define different time periods and their respective attempt limits.
    ///             These windows are sorted by duration in ascending order internally. Multiple windows allow for layered
    ///             rate limiting (e.g., "5 attempts per minute AND 100 attempts per hour").
    ///   - maxCacheSize: The maximum number of unique keys to track simultaneously. When exceeded, least recently used entries
    ///                  are evicted. Defaults to 10000.
    ///   - backoffMultiplier: The factor by which the backoff duration increases after each consecutive failure.
    ///                       For example, with a multiplier of 2.0 and a window of 1 hour, consecutive failures would
    ///                       result in backoff times of 2h, 4h, 8h, etc. Defaults to 2.0.
    ///   - metricsCallback: An optional async closure that's called after each rate limit check, receiving the key and result.
    ///                      Useful for monitoring and analytics. Defaults to nil.
    ///
    /// - Note: The windows array must not be empty. Windows are automatically sorted by duration to ensure consistent
    ///         rate limiting behavior.
    ///
    /// Example usage:
    /// ```swift
    /// let rateLimiter = RateLimiter<String>(
    ///     windows: [
    ///         .minutes(1, maxAttempts: 5),
    ///         .hours(1, maxAttempts: 100)
    ///     ],
    ///     maxCacheSize: 5000,
    ///     backoffMultiplier: 3.0
    /// )
    public init(
        windows: [WindowConfig],
        maxCacheSize: Int = 10000,
        backoffMultiplier: Double = 2.0,
        metricsCallback: ((Key, RateLimitResult) async -> Void)? = nil
    ) {
        self.windows = windows.sorted(by: { $0.duration < $1.duration })
        self.maxCacheSize = maxCacheSize
        self.backoffMultiplier = backoffMultiplier
        self.attemptsByKey = BoundedCache(capacity: maxCacheSize)
        self.metricsCallback = metricsCallback
    }
    
    public func checkLimit(
        _ key: Key,
        timestamp: Date = {
            @Dependency(\.date) var date
            return date()
        }()
    ) async -> RateLimitResult {
        await cleanup(before: timestamp)
        
        let infos = getCurrentWindows(key: key, timestamp: timestamp)
        
        // Check each window's limits
        for (windowConfig, info) in zip(windows, infos) {
            if info.attempts + 1 > windowConfig.maxAttempts {
                let nextWindow = info.windowStart.addingTimeInterval(windowConfig.duration)
                
                let backoff = calculateBackoff(consecutiveFailures: info.consecutiveFailures)
                
                let result = RateLimitResult(
                    isAllowed: false,
                    currentAttempts: info.attempts,
                    remainingAttempts: 0,
                    nextAllowedAttempt: nextWindow,
                    backoffInterval: backoff
                )
                
                await metricsCallback?(key, result)
                
                return result
            }
        }
        
        var updatedInfos = infos
        for i in 0..<updatedInfos.count {
            updatedInfos[i].attempts += 1
        }
        attemptsByKey.insert(updatedInfos, forKey: key)
        
        let result = RateLimitResult(
            isAllowed: true,
            currentAttempts: infos[0].attempts + 1,
            remainingAttempts: windows[0].maxAttempts - (infos[0].attempts + 1),
            nextAllowedAttempt: nil,
            backoffInterval: nil
        )
        
        await metricsCallback?(key, result)
        return result
    }
    
    public func recordFailure(_ key: Key) async {
        guard var infos = attemptsByKey.getValue(forKey: key) else { return }
        for i in 0..<infos.count {
            infos[i].consecutiveFailures += 1
        }
        attemptsByKey.insert(infos, forKey: key)
    }
    
    public func recordSuccess(_ key: Key) async {
        guard var infos = attemptsByKey.getValue(forKey: key) else { return }
        for i in 0..<infos.count {
            infos[i].consecutiveFailures = 0
        }
        attemptsByKey.insert(infos, forKey: key)
    }
    
    public func reset(_ key: Key) async {
        _ = attemptsByKey.removeValue(forKey: key)
    }
    
    
    private func getCurrentWindows(key: Key, timestamp: Date) -> [AttemptInfo] {
        let existing = attemptsByKey.getValue(forKey: key) ?? []
        var result: [AttemptInfo] = []
        
        for (i, window) in windows.enumerated() {
            let windowStart = getWindowStart(for: timestamp, duration: window.duration)
            
            if i < existing.count && existing[i].windowStart == windowStart {
                result.append(existing[i])
            } else {
                result.append(AttemptInfo(
                    windowStart: windowStart,
                    attempts: 0,
                    consecutiveFailures: existing.first?.consecutiveFailures ?? 0,
                    timestamp: timestamp
                ))
            }
        }
        
        return result
    }
    
    private func getWindowStart(for date: Date, duration: TimeInterval) -> Date {
        let windowSeconds = Int(duration)
        let timestamp = Int(date.timeIntervalSince1970)
        let windowStart = timestamp - (timestamp % windowSeconds)
        return Date(timeIntervalSince1970: Double(windowStart))
    }
    
    private func calculateBackoff(consecutiveFailures: Int) -> TimeInterval? {
        guard consecutiveFailures > 0 else { return nil }
        return pow(backoffMultiplier, Double(consecutiveFailures)) * windows[0].duration
    }
    
    private func cleanup(before date: Date) async {
        let oldestAllowedDate = windows.map { config in
            date.addingTimeInterval(-config.duration)
        }.min() ?? date
        
        attemptsByKey.filter { _, infos in
            infos.first?.timestamp ?? date > oldestAllowedDate
        }
    }
}

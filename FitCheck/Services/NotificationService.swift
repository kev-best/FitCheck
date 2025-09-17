//
//  NotificationServicing.swift
//  FitCheck
//
//  Created by csuftitan on 9/15/25.
//


import Foundation
import UserNotifications

// MARK: - Protocol
protocol NotificationServicing {
    func requestAuthorization() async throws
    func scheduleDailyFitCall(at date: Date) async throws
}

// MARK: - Mock
final class MockNotificationService: NotificationServicing {
    func requestAuthorization() async throws {
        let _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleDailyFitCall(at date: Date) async throws {
        // Stub: add your UNCalendarNotificationTrigger here
    }
}

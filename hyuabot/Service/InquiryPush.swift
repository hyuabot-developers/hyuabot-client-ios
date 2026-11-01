//
//  InquiryPush.swift
//  hyuabot
//

import Foundation

/// InquiryPushService.notifyAdminMessage (provider FCM) sends data {"type": "inquiry", "threadId": "<uuid>"}.
enum InquiryPush {
    static let providerFCM = "FCM"
    static let platformIOS = "IOS"
    static let typeKey = "type"
    static let typeInquiry = "inquiry"
    static let threadIdKey = "threadId"
    static let chatDeepLink = "hyuabot://inquiry"
    @MainActor static var isChatVisible = false

    static func isInquiryPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
        (userInfo[typeKey] as? String) == typeInquiry
    }
}

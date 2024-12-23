//
//  PollingManager.swift
//  hyuabot
//
//  Created by 이정인 on 12/23/24.
//

import SwiftUI

class PollingManager<T>: ObservableObject {
    let interval: TimeInterval
    private var timer: Timer?
    private var action: (() -> Void)?
    
    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func start(action: @escaping () -> Void) {
        self.action = action
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.action?()
        }
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
        self.action = nil
    }
}

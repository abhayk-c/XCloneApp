//
//  XDebouncer.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/14/25.
//

import Foundation

/**
 * A Debouncer with a Timer on the current run loop which can
 * be used to help throttle operations (apply a delay).
 */
public class XDebouncer {
    
    private var timer: Timer?
    private let timerDuration: TimeInterval
    private var performBlock: (() -> Void)?
    
    public init(_ delay: TimeInterval) {
        self.timerDuration = delay
    }
    
    public func perform(_ block: @escaping (() -> Void)) {
        invalidateTimer()
        performBlock = block
        timer = Timer.scheduledTimer(withTimeInterval: timerDuration, repeats: false, block: { [weak self] timer in
            guard let strongSelf = self else { return }
            strongSelf.performBlock?()
            strongSelf.invalidateTimer()
            strongSelf.performBlock = nil
        })
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
}

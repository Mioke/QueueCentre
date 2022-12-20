//
//  SchedulerCentre.swift
//  QueueCentre
//
//  Created by KelanJiang on 2022/12/15.
//

import Foundation
import RxSwift

public class SchedulerCentre {
    
    public static let shared: SchedulerCentre = .init()
    
    public private(set) var counters: [SchedulerPriority: Counter] = [:]
    
    let lock: UnfairLock = .init()
    
    /// Request a scheduler. *You should keep the instance if you repeatly using it rather than request one every time.*
    /// - Parameter priority: The priority of the scheduler.
    /// - Returns:  A scheduler.
    public static func scheduler(priority: SchedulerPriority = .`default`) -> SchedulerType {
        if let qos = priority.referenceToDisaptchQos() {
            return ObservedSerialDispatchQueueScheduler(qos: qos, priority: priority)
        }
        if priority == .ui {
            return RxSwift.MainScheduler.instance
        }
        fatalError("Priority of scheduler is unsupported.")
    }
    
    /// <#Description#>
    /// - Parameter priority: <#priority description#>
    /// - Returns: A async scheduler
    public static func asyncScheduler(priority: SchedulerPriority = .`default`) -> SchedulerType {
        if let qos = priority.referenceToDisaptchQos() {
            return ObservedConcurrentDispatchQueueScheduler(qos: qos)
        }
        if priority == .ui {
            return RxSwift.MainScheduler.asyncInstance
        }
        fatalError("Priority of scheduler is unsupported.")
    }
    
    /// Get a counter of the priority.
    /// - Parameter priority: The priority which counter count for.
    /// - Returns: The counter.
    public func getCounter(withPriority priority: SchedulerPriority) -> Counter {
        if let counter = self.counters[priority] {
            return counter
        }
        return lock.around {
            if let counter = self.counters[priority] {
                return counter
            }
            let counter = Counter()
            self.counters[priority] = counter
            return counter
        }
    }
}

extension SchedulerCentre {
    
    public enum SchedulerPriority {
        case background
        case low
        case `default`
        case ui
        case high
        case highest
        
        func referenceToDisaptchQos() -> DispatchQoS? {
            switch self {
            case .background:
                return .background
            case .low:
                return .utility
            case .`default`:
                return .`default`
            case .high:
                return .userInteractive
            case .highest:
                return .userInitiated
            case .ui:
                return nil
            }
        }
    }
    
}

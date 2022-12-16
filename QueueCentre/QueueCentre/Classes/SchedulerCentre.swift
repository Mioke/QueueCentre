//
//  SchedulerCentre.swift
//  QueueCentre
//
//  Created by KelanJiang on 2022/12/15.
//

import Foundation
import RxSwift

public class SchedulerCentre {
    
    public let shared: SchedulerCentre = .init()
    
    public let counters: [SchedulerPriority: Counter] = [:]
    
    /// Request a scheduler. *You should keep the instance if you repeatly using it rather than request one every time.*
    /// - Parameter priority: The priority of the scheduler.
    /// - Returns:  A scheduler.
    public static func scheduler(with priority: SchedulerPriority = .`default`) -> SchedulerType {
        if let qos = priority.referenceToDisaptchQos() {
            return ObservedSerialDispatchQueueScheduler(qos: qos)
        }
        if priority == .ui {
            return RxSwift.MainScheduler.instance
        }
        fatalError("Priority of scheduler is unsupported.")
    }
    
    /// <#Description#>
    /// - Parameter priority: <#priority description#>
    /// - Returns: A async scheduler
    public static func asyncScheduler(with priority: SchedulerPriority = .`default`) -> SchedulerType {
        if let qos = priority.referenceToDisaptchQos() {
            return ObservedConcurrentDispatchQueueScheduler(qos: qos)
        }
        if priority == .ui {
            return RxSwift.MainScheduler.asyncInstance
        }
        fatalError("Priority of scheduler is unsupported.")
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
            case .default:
                return .default
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

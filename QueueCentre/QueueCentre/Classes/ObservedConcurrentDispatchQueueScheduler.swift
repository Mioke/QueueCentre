//  Created by KelanJiang on 2022/12/16.

import Foundation
import RxSwift

public class ObservedConcurrentDispatchQueueScheduler: SchedulerType {
    public typealias TimeInterval = Foundation.TimeInterval
    public typealias Time = Date
    
    public var now : Date {
        Date()
    }
    
    let configuration: DispatchQueueConfiguration
    
    /// Constructs new `ConcurrentDispatchQueueScheduler` that wraps `queue`.
    ///
    /// - parameter queue: Target dispatch queue.
    /// - parameter leeway: The amount of time, in nanoseconds, that the system will defer the timer.
    public init(queue: DispatchQueue, leeway: DispatchTimeInterval = DispatchTimeInterval.nanoseconds(0), priority: SchedulerCentre.SchedulerPriority = .default) {
        self.configuration = DispatchQueueConfiguration(queue: queue, leeway: leeway)
        self.priority = priority
    }
    
    /// Convenience init for scheduler that wraps one of the global concurrent dispatch queues.
    ///
    /// - parameter qos: Target global dispatch queue, by quality of service class.
    /// - parameter leeway: The amount of time, in nanoseconds, that the system will defer the timer.
    public convenience init(qos: DispatchQoS, leeway: DispatchTimeInterval = DispatchTimeInterval.nanoseconds(0), priority: SchedulerCentre.SchedulerPriority = .default) {
        self.init(queue: DispatchQueue(
            label: "qc.observed_queue.\(qos)",
            qos: qos,
            attributes: [DispatchQueue.Attributes.concurrent],
            target: nil),
                  leeway: leeway,
                  priority: priority
        )
    }
    
    /// Inject observing before and after the action.
    /// - Parameter action: Original action
    /// - Returns: Observed action.
    final func observe<StateType, ReturnType>(action: @escaping (StateType) -> ReturnType) -> (StateType) -> ReturnType {
        return { [weak self] state -> ReturnType in
            if let self = self {
                SchedulerCentre.shared.getCounter(withPriority: self.priority).advance()
            }
            let metric = Metric(type: MetricMeasureType.self);
            defer {
                let duration = metric.call.end()
                print(duration)
            }
            return action(state)
        }
    }
    
    /**
     Schedules an action to be executed immediately.
     
     - parameter state: State passed to the action to be executed.
     - parameter action: Action to be executed.
     - returns: The disposable object used to cancel the scheduled action (best effort).
     */
    public final func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        self.configuration.schedule(state, action: observe(action: action))
    }
    
    /**
     Schedules an action to be executed.
     
     - parameter state: State passed to the action to be executed.
     - parameter dueTime: Relative time after which to execute the action.
     - parameter action: Action to be executed.
     - returns: The disposable object used to cancel the scheduled action (best effort).
     */
    public final func scheduleRelative<StateType>(_ state: StateType, dueTime: RxTimeInterval, action: @escaping (StateType) -> Disposable) -> Disposable {
        self.configuration.scheduleRelative(state, dueTime: dueTime, action: observe(action: action))
    }
    
    /**
     Schedules a periodic piece of work.
     
     - parameter state: State passed to the action to be executed.
     - parameter startAfter: Period after which initial work should be run.
     - parameter period: Period for running the work periodically.
     - parameter action: Action to be executed.
     - returns: The disposable object used to cancel the scheduled action (best effort).
     */
    public func schedulePeriodic<StateType>(_ state: StateType, startAfter: RxTimeInterval, period: RxTimeInterval, action: @escaping (StateType) -> StateType) -> Disposable {
        self.configuration.schedulePeriodic(state, startAfter: startAfter, period: period, action: observe(action: action))
    }
    
    
    // MARK: - Observing
    
    let priority: SchedulerCentre.SchedulerPriority
}

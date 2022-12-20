import RxSwift

/// Most of this class is copied from `SerialDispatchQueueScheduler`, aim to inject some logic in the `schedule` functions.
open class ObservedSerialDispatchQueueScheduler: SchedulerType {
    public typealias TimeInterval = Foundation.TimeInterval
    public typealias Time = Date
    
    /// - returns: Current time.
    public var now : Date {
        Date()
    }
    
    let configuration: DispatchQueueConfiguration
    
    /**
     Constructs new `SerialDispatchQueueScheduler` that wraps `serialQueue`.
     
     - parameter serialQueue: Target dispatch queue.
     - parameter leeway: The amount of time, in nanoseconds, that the system will defer the timer.
     */
    init(serialQueue: DispatchQueue, leeway: DispatchTimeInterval = DispatchTimeInterval.nanoseconds(0), priority: SchedulerCentre.SchedulerPriority = .default) {
        self.configuration = DispatchQueueConfiguration(queue: serialQueue, leeway: leeway)
        self.priority = priority
    }
    
    /**
     Constructs new `SerialDispatchQueueScheduler` with internal serial queue named `internalSerialQueueName`.
     
     Additional dispatch queue properties can be set after dispatch queue is created using `serialQueueConfiguration`.
     
     - parameter internalSerialQueueName: Name of internal serial dispatch queue.
     - parameter serialQueueConfiguration: Additional configuration of internal serial dispatch queue.
     - parameter leeway: The amount of time, in nanoseconds, that the system will defer the timer.
     */
    public convenience init(internalSerialQueueName: String, serialQueueConfiguration: ((DispatchQueue) -> Void)? = nil, leeway: DispatchTimeInterval = DispatchTimeInterval.nanoseconds(0), priority: SchedulerCentre.SchedulerPriority = .default) {
        let queue = DispatchQueue(label: internalSerialQueueName, attributes: [])
        serialQueueConfiguration?(queue)
        self.init(serialQueue: queue, leeway: leeway, priority: priority)
    }
    
    /**
     Constructs new `SerialDispatchQueueScheduler` named `internalSerialQueueName` that wraps `queue`.
     
     - parameter queue: Possibly concurrent dispatch queue used to perform work.
     - parameter internalSerialQueueName: Name of internal serial dispatch queue proxy.
     - parameter leeway: The amount of time, in nanoseconds, that the system will defer the timer.
     */
    public convenience init(queue: DispatchQueue, internalSerialQueueName: String, leeway: DispatchTimeInterval = DispatchTimeInterval.nanoseconds(0), priority: SchedulerCentre.SchedulerPriority = .default) {
        // Swift 3.0 IUO
        let serialQueue = DispatchQueue(label: internalSerialQueueName,
                                        attributes: [],
                                        target: queue)
        self.init(serialQueue: serialQueue, leeway: leeway, priority: priority)
    }
    
    /**
     Constructs new `SerialDispatchQueueScheduler` that wraps one of the global concurrent dispatch queues.
     
     - parameter qos: Identifier for global dispatch queue with specified quality of service class.
     - parameter internalSerialQueueName: Custom name for internal serial dispatch queue proxy.
     - parameter leeway: The amount of time, in nanoseconds, that the system will defer the timer.
     */
    @available(macOS 10.10, *)
    public convenience init(qos: DispatchQoS, internalSerialQueueName: String = "qc.observed_global_dispatch_queue.serial", leeway: DispatchTimeInterval = DispatchTimeInterval.nanoseconds(0), priority: SchedulerCentre.SchedulerPriority = .default) {
        self.init(queue: DispatchQueue.global(qos: qos.qosClass), internalSerialQueueName: internalSerialQueueName, leeway: leeway, priority: priority)
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
        return self.scheduleInternal(state, action: observe(action: action))
    }
    
    func scheduleInternal<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        self.configuration.schedule(state, action: action)
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

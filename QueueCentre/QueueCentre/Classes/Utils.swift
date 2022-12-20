//
//  Utils.swift
//  QueueCentre
//
//  Created by KelanJiang on 2022/12/15.
//

import Foundation

public class Counter: CustomDebugStringConvertible {
    public var value: Atomic<UInt64>
    
    public init(value: UInt64 = 0) {
        self.value = .init(value: value)
    }
    
    @discardableResult
    public func advance() -> UInt64 {
        return value.modify { val in
            val += 1
            return val
        }
    }
    
    public var debugDescription: String {
        return "\(value.unsafeValue)"
    }
}

public struct Metric<MetricType> where MetricType: MetricTypeProtocol {
        
    let instance: MetricType
    
    public init(type: MetricType.Type) {
        self.instance = type.init()
    }
    
    public var call: MetricType {
        return instance
    }
}

public protocol MetricTypeProtocol {
    init()
}

public struct MetricMeasureType: MetricTypeProtocol {
    
    let startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    
    public init() { }
    
    public func end() -> CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent() - startTime
    }
}

public struct MetricRecordType: MetricTypeProtocol {
    
    public var options: Options
    public var data: Data?
    
    public init() {
        options = []
    }
    
    public init(options: Options) {
        self.options = options
    }
    
    public struct Options: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let jsonData = Options.init(rawValue: 1 << 0)
    }
}

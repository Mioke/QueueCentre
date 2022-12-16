//
//  Utils.swift
//  QueueCentre
//
//  Created by KelanJiang on 2022/12/15.
//

import Foundation

public class Counter {
    public var value: Atomic<UInt64>
    
    public init(value: UInt64 = 0) {
        self.value = .init(value: value)
    }
    
    public func advance() -> UInt64 {
        return value.modify { val in
            val += 1
            return val
        }
    }
}

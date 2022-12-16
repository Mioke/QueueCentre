//
//  ViewController.swift
//  QueueCentre
//
//  Created by KelanJiang on 12/15/2022.
//  Copyright (c) 2022 KelanJiang. All rights reserved.
//

import UIKit
import QueueCentre
import RxSwift
import ObjectiveC

class ViewController: UIViewController {
    
    let coordinator: Coordinator = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        coordinator.requestBatchData()
            .subscribe(on: ConcurrentMainScheduler.instance)
            .subscribe { vms in
                print(vms)
            } onError: { error in
                print(error)
            }
            .disposed(by: self.lifetimeBag)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class Coordinator {
    
//    let workGroup: QueueCentre.WorkGroup = .priority(.default)
    let processQueue: SerialDispatchQueueScheduler = .init(qos: .default)
    
    let provider: Provider = .init()
    let store: Store = .init()
    
    func requestBatchData() -> Observable<[ViewModel]> {
        /*
         
         */
        let query: Observable<[TCPModel]> = provider.sendRequest()
        
        return query.map { $0.map { StoreModel(tcpModel: $0) } }
            .flatMapLatest(store.save(model:))
            .subscribe(on: processQueue)
            .map { $0.map { ViewModel(model: $0) } }
    }
}

class Provider {
//    let workGroup: QueueCentre.WorkGroup = .priority(.default)
    
    let sendingQueue: ConcurrentDispatchQueueScheduler = .init(qos: .default)
    let reportingQueue: ConcurrentDispatchQueueScheduler = .init(qos: .default)
    
    func sendRequest<Result: Codable>() -> Observable<Result> {
        return Observable<Data>
            .create({ ob in
                // *Mock*
                let tcpModel = [TCPModel(name: "Klein", value: "25")]
                ob.onNext(try! JSONEncoder().encode(tcpModel))
                return Disposables.create()
                // *Mock*
            })
            .observe(on: sendingQueue)
            .delay(.seconds(1), scheduler: reportingQueue)
//            .subscribe(on: reportingQueue)
            .map { data in
                return try JSONDecoder().decode(Result.self, from: data)
            }
    }
    
}

class Store {
//    let workGroup: QueueCentre.WorkGroup = .priority(.high)
    
//    func store(models: [StoreModel]) -> Work<Void, [StoreModel]> {
//        return workGroup.task {
//            print("Saved")
//            return Observable.just(models)
//        }
//    }
    
    let recordQueue: SerialDispatchQueueScheduler = .init(qos: .userInteractive)
    let reportingQueue: ConcurrentDispatchQueueScheduler = .init(qos: .default)
    
    func save<Model: Codable>(model: Model) -> Observable<Model> {
        return Observable<Model>.just(model)
            .subscribe(on: recordQueue)
            .flatMapLatest { model in
                print("Saved")
                return Observable<Model>.just(model)
            }
            .subscribe(on: reportingQueue)
    }
}

struct ViewModel {
    let name: String
    let value: String
    let updateTime: Date
    
    init(model: StoreModel) {
        self.name = model.name
        self.value = model.value
        self.updateTime = model.updateTime
    }
}

struct TCPModel: Codable {
    let name: String
    let value: String
}

protocol TCPModelConvertible {
    associatedtype RequestModel
    init(tcpModel: RequestModel)
}

struct StoreModel: Codable {
    let name: String
    let value: String
    let updateTime: Date
}

extension StoreModel: TCPModelConvertible {
    
    typealias RequestModel = TCPModel
    
    init(tcpModel: RequestModel) {
        self.name = tcpModel.name
        self.value = tcpModel.value
        self.updateTime = Date()
    }
}

extension NSObject {
    
    var lifetimeBag: DisposeBag {
        
        var rawPointer: UnsafeRawPointer?
        withUnsafePointer(to: #function) { pointer in
            rawPointer = .init(pointer)
        }
        
        if let bag = objc_getAssociatedObject(self, rawPointer!) as? DisposeBag {
            return bag
        } else {
            let new = DisposeBag()
            objc_setAssociatedObject(self, rawPointer!, new, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return new
        }
    }
}

//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa



// Support code -- DO NOT REMOVE
class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
  static func make() -> TimelineView<E> {
    return TimelineView(width: 400, height: 100)
  }
  public func on(_ event: Event<E>) {
    switch event {
    case .next(let value):
      add(.Next(String(describing: value)))
    case .completed:
      add(.Completed())
    case .error(_):
      add(.Error())
    }
  }
}

let elementsPerSecond = 1
let maxElements = 5
let replayElements = 2
let replayDelay: TimeInterval = 3

//let sourceObservable = Observable<Int>.create { (observable) in
//    var value = 1
//    let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: DispatchQueue.main, handler: {
//        if value <= maxElements {
//            observable.onNext(value)
//            value += 1
//        }
//    })
//    return Disposables.create {
//        timer.suspend()
//    }
//    }.replayAll()

let sourceObservable = Observable<Int>
    .interval(RxTimeInterval(1.0 / Double(elementsPerSecond)), scheduler: MainScheduler.instance)
    .replay(replayElements)

let sourceTimeline = TimelineView<Int>.make()
let replayedTimeline = TimelineView<Int>.make()

let stack = UIStackView.makeVertical([
    UILabel.makeTitle("replay"),
    UILabel.make("Emit \(elementsPerSecond) per second:"),
    sourceTimeline,
    UILabel.make("Replay \(replayElements) after \(replayDelay) sec:"),
    replayedTimeline
    ])

_ = sourceObservable.subscribe(sourceTimeline)

DispatchQueue.main.asyncAfter(deadline: .now() + replayDelay) {
    _ = sourceObservable.subscribe(replayedTimeline)
}

_ = sourceObservable.connect()

let hostView = setupHostView()
hostView.addSubview(stack)
hostView

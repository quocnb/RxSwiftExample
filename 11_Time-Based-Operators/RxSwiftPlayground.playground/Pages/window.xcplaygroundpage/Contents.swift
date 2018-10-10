//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa

// Support code -- DO NOT REMOVE
class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
  static func make() -> TimelineView<E> {
    let view = TimelineView(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
    view.setup()
    return view
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
let windowTimeSpan: RxTimeInterval = 4
let windowMaxCount = 10
let sourceObservable = PublishSubject<String>()

let sourceTimeline = TimelineView<String>.make()

let stackX = UIStackView.makeVertical([
    UILabel.makeTitle("window"),
    UILabel.make("Emitted elements (\(elementsPerSecond) per sec.):"),
    sourceTimeline,
    UILabel.make("Windowed observables (at most \(windowMaxCount) every \(windowTimeSpan) sec):")
])

_ = sourceObservable.subscribe(sourceTimeline)

sourceObservable.window(timeSpan: windowTimeSpan, count: windowMaxCount, scheduler: MainScheduler.instance)
    .flatMap { windowedObservable -> Observable<(TimelineView<Int>, String?)> in
        let timeline = TimelineView<Int>.make()
        stackX.insert(timeline, at: 4)
        stackX.keep(atMost: 8)
        return windowedObservable
            .map { value in (timeline, value) }
            .concat(Observable.just((timeline, nil)))
    }.subscribe(onNext: { (tuples) in
        let (timeline, value) = tuples
        if let value = value {
            timeline.add(.Next(value))
        } else {
            timeline.add(.Completed(true))
        }
    })

let hostView = setupHostView()
hostView.addSubview(stackX)
hostView

let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
    sourceObservable.onNext("a")
}

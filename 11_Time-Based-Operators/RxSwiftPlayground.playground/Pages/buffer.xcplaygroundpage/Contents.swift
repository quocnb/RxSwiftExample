//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa

// Support code -- DO NOT REMOVE 16:05
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

let bufferTimeSpan: RxTimeInterval = 5
let bufferMaxCount = 5
let sourceObservable = PublishSubject<String>()

let sourceTimeline  = TimelineView<String>.make()
let bufferedTimeline = TimelineView<Int>.make()

let stackView = UIStackView.makeVertical([
    UILabel.makeTitle("buffered"),
    UILabel.make("Emitted elements:"),
    sourceTimeline,
    UILabel.make("Buffered elements (at most \(bufferMaxCount) every \(bufferTimeSpan) seconds):"),
    bufferedTimeline
    ])

_ = sourceObservable.subscribe(sourceTimeline)

sourceObservable.buffer(timeSpan: bufferTimeSpan, count: bufferMaxCount, scheduler: MainScheduler.instance)
    .map({$0.count})
    .subscribe(bufferedTimeline)

let hostView = setupHostView()
hostView.addSubview(stackView)
hostView

let elementsPerSecond = 0.7
let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
    sourceObservable.onNext("😹")
}

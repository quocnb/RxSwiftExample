//: Please build the scheme 'RxSwiftPlayground' first
import RxSwift

extension Observable {
    func printEvent() -> Disposable {
        return self.subscribe { (event) in
            if event.isCompleted {
                print("Completed")
            } else if let element = event.element {
                print(element)
            } else if let error = event.error {
                print(error.localizedDescription)
            }
        }
    }
}

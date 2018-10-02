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

extension PublishSubject where Element == String {
    func callTest() {
        self.onNext("Hello")
        self.onNext("It's me")
        self.onNext("Adele")
    }
}

example(of: "Ignore Element") {
    let bag = DisposeBag()
    let strikes = PublishSubject<String>()
    strikes.ignoreElements().subscribe(onCompleted: {
        print("Complete")
    }, onError: { (error) in
        print("Error:", error.localizedDescription)
    }).disposed(by: bag)
    strikes.onNext("hello")
    strikes.onNext("it's me")
    strikes.onNext("Adele")
    strikes.onCompleted()
}

example(of: "Element at") {
    let bag = DisposeBag()
    let strikes = PublishSubject<String>()
    strikes.elementAt(2).printEvent().disposed(by: bag)
    strikes.callTest()
}

example(of: "Filter") {
    let bag = DisposeBag()
    Observable.of(1, 2, 3, 4, 5, 6).filter({ (num) -> Bool in
        return num % 2 == 0
    }).printEvent().disposed(by: bag)
}

example(of: "Skipping") {
    let bag = DisposeBag()
    let strikes = PublishSubject<String>()
    strikes.skip(2).printEvent().disposed(by: bag)
    strikes.callTest()
}

example(of: "Skip while") {
    let bag = DisposeBag()
    Observable.of(1, 2, 3, 4, 5, 6).skipWhile({ (number) -> Bool in
        return number % 2 == 1
    }).printEvent().disposed(by: bag)
}

example(of: "Skip Util") {
    let bag = DisposeBag()
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<Int>()
    subject.skipUntil(trigger).printEvent().disposed(by: bag)
    subject.onNext("Begin test")
    subject.onNext("But not begin yet, waiting for trigger")
    trigger.onNext(1)
    subject.callTest()
}

example(of: "Taking operator") {
    let bag = DisposeBag()
    let subject = PublishSubject<String>()
    let copySubject = subject.take(1)
    copySubject.printEvent().disposed(by: bag)
    subject.callTest()
}

example(of: "Take while") {
    let bag = DisposeBag()
    Observable.of(1, 3, 5, 2, 5, 6).takeWhile({$0 % 2 == 1}).printEvent().disposed(by: bag)
}

example(of: "Take Util") {
    let bag = DisposeBag()
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<Int>()
    subject.takeUntil(trigger).printEvent().disposed(by: bag)
    subject.onNext("Begin test")
    subject.onNext("But not begin yet, waiting for trigger")
    trigger.onNext(1)
    subject.callTest()
}

example(of: "Distinct until change") {
    let bag = DisposeBag()
    Observable.of("A", "A", "B", "B", "A", "A")
        .distinctUntilChanged().printEvent().disposed(by: bag)
}

example(of: "Distinc Until Change(:)") {
    let bag = DisposeBag()
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    Observable<NSNumber>.of(10, 110, 20, 200, 210, 310).distinctUntilChanged({ (num1, num2) -> Bool in
        guard let num1Words = formatter.string(from: num1)?.components(separatedBy: " "),
            let num2Words = formatter.string(from: num2)?.components(separatedBy: " ")
        else {
            return false
        }
        print(num1Words)
        print(num2Words)
        var containsMatch = false

        for num1Word in num1Words {
            if num2Words.contains(num1Word) {
                containsMatch = true
                break
            }
        }
        return containsMatch
    }).printEvent().disposed(by: bag)
}

// CHALLENGER 1: Create a phone number lookup
example(of: "Challenge 1: Create a phone number lookup") {

    let disposeBag = DisposeBag()

    let contacts = [
        "603-555-1212": "Florent",
        "212-555-1212": "Junior",
        "408-555-1212": "Marin",
        "617-555-1212": "Scott"
    ]

    func phoneNumber(from inputs: [Int]) -> String {
        var phone = inputs.map(String.init).joined()

        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 3)
        )

        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 7)
        )

        return phone
    }

    let input = PublishSubject<Int>()
    input.skipWhile({ (num) -> Bool in
        return num == 0
    }).filter({ (num) -> Bool in
        return num >= 0 && num <= 9
    }).take(10).toArray().subscribe({ (event) in
        guard let numbers = event.element else {
            return
        }
        let phone = phoneNumber(from: numbers)
        if let contact = contacts[phone] {
            print("Dialing \(contact) (\(phone))...")
        } else {
            print("Contact not found")
        }
    }).disposed(by: disposeBag)


    input.onNext(0)
    input.onNext(603)

    input.onNext(2)
    input.onNext(1)

    // Confirm that 7 results in "Contact not found", and then change to 2 and confirm that Junior is found
    input.onNext(2)

    "5551212".forEach {
        if let number = (Int("\($0)")) {
            input.onNext(number)
        }
    }

    input.onNext(9)
}

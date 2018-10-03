//: Please build the scheme 'RxSwiftPlayground' first
import RxSwift
import RxSwiftExt

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

// Transforming elements
example(of: "toArray") {
    let bag = DisposeBag()
    Observable.of(1, 2, 3).toArray().printEvent().disposed(by: bag)
}

example(of: "map") {
    let bag = DisposeBag()
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    let ob = Observable.of(1, 3, 4)
    ob.map({ (num) -> String in
        return formatter.string(from: NSNumber(integerLiteral: num)) ?? ""
    }).printEvent().disposed(by: bag)
    let subj = PublishSubject<String>()
    subj.map({ (string) -> String in
        return string + "XXX"
    }).printEvent().disposed(by: bag)
    subj.onNext("haha")
}

example(of: "Enumered") {
    let bag = DisposeBag()
    Observable.of(1, 2, 3, 4).enumerated().printEvent().disposed(by: bag)
}

// Transforming inner observables
struct Student {
    var score: BehaviorSubject<Int>
}

example(of: "flat map") {
    let bag = DisposeBag()
    let ryan = Student(score: BehaviorSubject(value: 80))
    let char = Student(score: BehaviorSubject(value: 90))

    let student = PublishSubject<Student>()
    student.flatMap({$0.score}).printEvent().disposed(by: bag)
    student.onNext(ryan)
    ryan.score.onNext(85)
    student.onNext(char)
    ryan.score.onNext(95)
    char.score.onNext(100)
}

example(of: "flat map lastest") {
    let bag = DisposeBag()
    let ryan = Student(score: BehaviorSubject(value: 80))
    let char = Student(score: BehaviorSubject(value: 90))

    let student = PublishSubject<Student>()
    student.flatMapLatest({ $0.score }).printEvent().disposed(by: bag)
    student.onNext(ryan)
    ryan.score.onNext(85)
    student.onNext(char)
    ryan.score.onNext(95)
    char.score.onNext(100)
}

example(of: "materialize and dematerialize") {
    enum MyError: Error {
        case anError
    }
    let disposeBag = DisposeBag()

    let ryan = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 100))
    let student = BehaviorSubject(value: ryan)
    let studentScore = student.flatMapLatest {
        $0.score.materialize()
    }
    studentScore.filter({ (event) -> Bool in
        if event.error == nil {
            return true
        } else {
            return false
        }
    }).dematerialize().subscribe(onNext: {
        print($0)
    }).disposed(by: disposeBag)
    ryan.score.onNext(85)
    ryan.score.onError(MyError.anError)
    ryan.score.onNext(90)

    student.onNext(charlotte)
}


example(of: "Challenge 1") {
    let disposeBag = DisposeBag()

    let contacts = [
        "603-555-1212": "Florent",
        "212-555-1212": "Junior",
        "408-555-1212": "Marin",
        "617-555-1212": "Scott"
    ]

    let convert: (String) -> UInt? = { value in
        if let number = UInt(value),
            number < 10 {
            return number
        }

        let keyMap: [String: UInt] = [
            "abc": 2, "def": 3, "ghi": 4,
            "jkl": 5, "mno": 6, "pqrs": 7,
            "tuv": 8, "wxyz": 9
        ]

        let converted = keyMap
            .filter { $0.key.contains(value.lowercased()) }
            .map { $0.value }
            .first

        return converted
    }

    let format: ([UInt]) -> String = {
        var phone = $0.map(String.init).joined()

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

    let dial: (String) -> String = {
        if let contact = contacts[$0] {
            return "Dialing \(contact) (\($0))..."
        } else {
            return "Contact not found"
        }
    }

    let input = Variable<String>("")
    // Add your code here
    input.asObservable()
        .map({convert($0)})
        .unwrap()
        .skipWhile({$0 == 0})
        .take(10)
        .toArray().map({format($0)})
        .subscribe(onNext: { print(dial($0)) })
        .disposed(by: disposeBag)

    input.value = ""
    input.value = "0"
    input.value = "408"

    input.value = "6"
    input.value = ""
    input.value = "0"
    input.value = "3"

    "JKL1A1B".forEach {
        input.value = "\($0)"
    }

    input.value = "9"
}

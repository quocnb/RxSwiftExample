//: Please build the scheme 'RxSwiftPlayground' first
import RxSwift
import RxSwiftExt

let bag = DisposeBag()

example(of: "start with") {
    let numbers = Observable.of(1, 2, 3, 4)
    let observable = numbers.startWith(1, 3)
    observable.subscribe(onNext: { (num) in
        print(num)
    }).disposed(by: bag)
}

example(of: "concat") {
    let observable1 = Observable.of(1, 3, 5, 7, 9)
    let observable2 = Observable.of(2, 4, 6, 8, 0)
    observable1.concat(observable2).subscribe(onNext: { (num) in
        print(num)
    }).disposed(by: bag)
}

example(of: "concatMap") {
    let sequences = [
        "Germany": Observable.of("Berlin", "Münich", "Frankfurt"),
        "Spain": Observable.of("Madrid", "Barcelona", "Valencia")
    ]
    let observable = Observable.of("Germany", "Spain")
        .concatMap { country in sequences[country] ?? .empty() }
    observable.subscribe(onNext: { string in
        print(string)
    }).disposed(by: bag)
}

example(of: "merge") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    let source = Observable.of(left.asObserver(), right.asObserver())
    let observable = source.merge()
    let disposable = observable.subscribe(onNext: { (text) in
        print(text)
    })
    var leftValues = ["Berlin", "Munich", "Frankfurt"]
    var rightValues = ["Madrid", "Barcelona", "Valencia"]
    repeat {
        if [0,1].randomElement() == 0 {
            if !leftValues.isEmpty {
                left.onNext("Left:  " + leftValues.removeFirst())
            }
        } else if !rightValues.isEmpty {
            right.onNext("Right: " + rightValues.removeFirst())
        }
    } while !leftValues.isEmpty || !rightValues.isEmpty
    disposable.dispose()
}

example(of: "combineLatest") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    let observable = Observable.combineLatest(left, right, resultSelector: {
        lastLeft, lastRight in
        "\(lastLeft) \(lastRight)"
    })
    let disposable = observable.subscribe(onNext: { value in
        print(value)
    })
    print("> Sending a value to Left")
    left.onNext("Hello,")
    print("> Sending a value to Right")
    right.onNext("world")
    print("> Sending another value to Right")
    right.onNext("RxSwift")
    print("> Sending another value to Left")
    left.onNext("Have a good day, ")

    disposable.dispose()
}

example(of: "combineLastest") {
    let choice : Observable<DateFormatter.Style> = Observable.of(.short, .long)
    let dates = Observable.of(Date(), Date(timeIntervalSinceNow: 7*24*3600))
    let observable = Observable.combineLatest(choice, dates) {
        (format, when) -> String in
        let formatter = DateFormatter()
        formatter.dateStyle = format
        return formatter.string(from: when)
    }
    observable.subscribe(onNext: { value in
        print(value)
    })
}

example(of: "zip") {
    enum Weather {
        case cloudy
        case sunny
    }
    let left: Observable<Weather> = Observable.of(.sunny, .cloudy, .cloudy, .sunny)
    let right = Observable.of("Lisbon", "Copenhagen", "London", "Madrid", "Vienna")
    let observable = Observable.zip(left, right) { weather, city in
        return "It's \(weather) in \(city)"
    }
    observable.subscribe(onNext: { value in
        print(value)
    })
}

example(of: "withLatestFrom") {
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()
    let observable = button.withLatestFrom(textField)
    let dispose1 = observable.subscribe(onNext: { value in
        print("1)", value)
    })
    let observable2 = textField.sample(button)
    let dispose2 = observable2.subscribe(onNext: { (value) in
        print("2)", value)
    })
    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    button.onNext(())
    button.onNext(())
    dispose1.dispose()
    dispose2.dispose()
}

example(of: "Swiftch") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    let observable = left.amb(right)
    let disposable = observable.subscribe(onNext: { value in
        print(value)
    })

    right.onNext("Copenhagen")
    left.onNext("Lisbon")
    left.onNext("London")
    left.onNext("Madrid")
    right.onNext("Vienna")
    disposable.dispose()
}

example(of: "switchLatest") {
    // 1
    let one = PublishSubject<String>()
    let two = PublishSubject<String>()
    let three = PublishSubject<String>()
    let source = PublishSubject<Observable<String>>()
    let observable = source.switchLatest()
    let disposable = observable.subscribe(onNext: { value in
        print(value)
    })
    source.onNext(one)
    one.onNext("Some text from sequence one")
    two.onNext("Some text from sequence two")
    source.onNext(two)
    two.onNext("More text from sequence two")
    one.onNext("and also from sequence one")
    source.onNext(three)
    two.onNext("Why don't you see me?")
    one.onNext("I'm alone, help me")
    three.onNext("Hey it's three. I win.")
    source.onNext(one)
    one.onNext("Nope. It's me, one!")
    disposable.dispose()
}


example(of: "reduce") {
    let source = Observable.of(1, 3, 5, 7, 9)
    let observable = source.reduce(0, accumulator: +)
    observable.subscribe(onNext: { (num) in
        print(num)
    })
}

example(of: "scan") {
    let source = Observable.of(1, 3, 5, 7, 9)
    let observable = source.scan(0, accumulator: +)
    let zipResult = source.zip(with: observable, resultSelector: { (currentValue, result) in
        return (currentValue, result)
    })
    zipResult.subscribe(onNext: { (num) in
        print(num)
    })
}

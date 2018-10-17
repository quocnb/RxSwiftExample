### Chap 10: Combining Operators in Practice

#### 1. Explain difficult to understand points

**?:** Why `eoCategories.concat(updatedCategories)` but not simple use `updatedCategories` in

```
let eoCategories = EONET.categories
        let downloadedEvents = EONET.events(forLast: 360)
        let updatedCategories = Observable<[EOCategory]>.combineLatest(eoCategories, downloadedEvents)
        // new code below

        eoCategories.concat(updatedCategories)
            .bind(to: self.categories)
            // code below
```

**->:** After the eoCategories auto call `onComplete`, `concat` will be return only updatedCategories

#### 2. NSObject+Rx

Say goodbye with
```
let bag = DisposeBag()
```
in every file with `NSObject+Rx` by `RxSwiftCommunity`.

Simple do
```
disposed(by: rx.disposeBag)
```

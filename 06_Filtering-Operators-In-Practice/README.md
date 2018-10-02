### Chap 06 :  Filtering Operators in Practice

Every times you call `Observable.create` or `subject.asObservable` it created a new Observable instance. It can make the change of data out of control. So, `share()` is a good solution for avoid it.

**`share()`'s simple explain :**

Simple call `subject.asObservable` or `Observable.create`
![](./06_Share_Example_1.png)

Using share()

![](./06_Share_Example_2.png)

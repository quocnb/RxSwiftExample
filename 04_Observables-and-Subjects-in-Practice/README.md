### Chap 04 : Observables and Subjects in Practice

A sample example for Section 1

Using Subjects (BehaviorRelay of RxCocoa, or Variables of RxSwift) for update the imageView base on change of selected images.

**Questions:**
- In the `MainViewController`

```
images.catchOnNext { [weak self] photos in
    guard let preview = self?.imagePreview else {
        return
    }
    preview.image = UIImage.collage(images: photos, size: preview.frame.size)
}.disposed(by: bag)

images.catchOnNext { [weak self](photos) in
    self?.updateUI(photos: photos)
}.disposed(by: bag)
```
Why we put 2 subscribe, one for collage image, one for updateUI.

- In the `PhotosViewController`, we have
```
private let selectedPhotoSubject = PublishSubject<UIImage>()
var selectedPhotos: Observable<UIImage> {
    return selectedPhotoSubject.asObservable()
}
```
why we use `selectedPhotos` instead of set `selectedPhotoSubject` to internal and direct call `selectedPhotoSubject.asObservable`

- Why we should use the `Single` instead of normal `Observables`

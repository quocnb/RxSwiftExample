/*
 * Copyright (c) 2016-present Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift
import RxCocoa

class MainViewController: UIViewController {

    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!

    private let bag = DisposeBag()
    private let images = BehaviorRelay<[UIImage]>(value: [])

    override func viewDidLoad() {
        super.viewDidLoad()
        images.catchOnNext { [weak self] photos in
            guard let preview = self?.imagePreview else {
                return
            }
            preview.image = UIImage.collage(images: photos, size: preview.frame.size)
        }.disposed(by: bag)

        images.catchOnNext { [weak self](photos) in
            self?.updateUI(photos: photos)
        }.disposed(by: bag)
    }

    @IBAction func actionClear() {
        self.images.clear()
    }

    @IBAction func actionSave() {
        guard let image = self.imagePreview.image else {
            return
        }
        PhotoWriter.save(image).asSingle().subscribe(onSuccess: { [weak self] id in
            self?.showMessage("Saved with id: \(id)")
            self?.actionClear()
        }) { [weak self] error in
            self?.showMessage("Error", description: error.localizedDescription)
        }.disposed(by: bag)
    }

    @IBAction func actionAdd() {
//        self.images.append(#imageLiteral(resourceName: "IMG_1907.jpg"))
        let photosViewController = storyboard!.instantiateViewController(
            withIdentifier: "PhotosViewController") as! PhotosViewController
        navigationController!.pushViewController(photosViewController, animated: true)
        photosViewController.selectedPhotos.subscribe(onNext: { [weak self](photo) in
            self?.images.append(photo)
        }, onDisposed: {
            print("completed photo selection")
        }).disposed(by: bag)
    }

    func showMessage(_ title: String, description: String? = nil) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
        present(alert, animated: true, completion: nil)
    }

    private func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }
}

extension BehaviorRelay where Element == [UIImage] {
    func append(_ element: UIImage) {
        self.accept(self.value + [element])
    }

    func clear() {
        self.accept([])
    }

    func catchOnNext(_ nextEvent: @escaping ([UIImage]) -> Void) -> Disposable {
        return self.asObservable().subscribe(onNext: nextEvent)
    }
}

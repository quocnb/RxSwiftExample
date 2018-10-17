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

    private var imageCache = [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let imagesObservable = images.asObservable().share()
        imagesObservable
            .throttle(1.0, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] photos in
                self.imagePreview.image = UIImage.collage(images: photos, size: self.imagePreview.frame.size)
            }).disposed(by: bag)
        imagesObservable.subscribe(onNext: { [weak self](photos) in
            self?.updateUI(photos: photos)
        }).disposed(by: bag)
    }

    @IBAction func actionClear() {
        self.images.clear()
        imageCache = []
        self.updateNavigationIcon()
    }

    @IBAction func actionSave() {
        guard let image = self.imagePreview.image else {
            return
        }
        PhotoWriter.save(image).subscribe(onSuccess: { [weak self](id) in
            self?.showMessage("Saved with id: \(id)")
            self?.actionClear()
        }) { [weak self](error) in
            self?.showMessage("Error", description: error.localizedDescription)
        }.disposed(by: bag)
    }

    @IBAction func actionAdd() {
//        self.images.append(#imageLiteral(resourceName: "IMG_1907.jpg"))
        let photosViewController = storyboard!.instantiateViewController(
            withIdentifier: "PhotosViewController") as! PhotosViewController
        navigationController!.pushViewController(photosViewController, animated: true)
        let newPhotos = photosViewController.selectedPhotos.share()
        newPhotos.filter({ (image) -> Bool in
            return image.size.width > image.size.height
        }).filter({ [weak self](image) -> Bool in
            let length = image.pngData()?.count ?? 0
            if self?.imageCache.contains(length) == true {
                return false
            }
            self?.imageCache.append(length)
            return true
        }).takeWhile({ [weak self](_) -> Bool in
            (self?.images.value.count ?? 0) < 6
        }).subscribe(onNext: { [weak self](photo) in
            self?.images.append(photo)
        }, onDisposed: {
            print("completed photo selection")
        }).disposed(by: photosViewController.bag)
        newPhotos.ignoreElements().subscribe(onCompleted: { [weak self] in
            self?.updateNavigationIcon()
        }).disposed(by: photosViewController.bag)
    }

    func showMessage(_ title: String, description: String? = nil) {
        self.showAlert(title, description: description).subscribe().disposed(by: bag)
    }

    private func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }

    private func updateNavigationIcon() {
        let icon = imagePreview.image?
            .scaled(CGSize(width: 22, height: 22))
            .withRenderingMode(.alwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon,
                                                           style: .done, target: nil, action: nil)
    }
}

extension BehaviorRelay where Element == [UIImage] {
    func append(_ element: UIImage) {
        self.accept(self.value + [element])
    }

    func clear() {
        self.accept([])
    }
}

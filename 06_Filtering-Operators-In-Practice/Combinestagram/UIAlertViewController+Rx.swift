//
//  UIAlertViewController+Rx.swift
//  Combinestagram
//
//  Created by Quoc Nguyen on 2018/10/02.
//  Copyright © 2018 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {
    func showAlert(_ title: String, description: String?) -> Completable {
        return Completable.create(subscribe: { [weak self](completable) -> Disposable in
            let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
                completable(CompletableEvent.completed)
            }))
            self?.present(alert, animated: true, completion: nil)
            return Disposables.create {
                self?.dismiss(animated: true, completion: nil)
            }
        })
    }
}


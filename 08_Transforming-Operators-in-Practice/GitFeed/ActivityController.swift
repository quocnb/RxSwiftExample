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
import Kingfisher

func cachedFileURL(_ fileName: String) -> URL {
    return FileManager.default
        .urls(for: .cachesDirectory, in: .allDomainsMask)
        .first!
        .appendingPathComponent(fileName)
}

class ActivityController: UITableViewController {
    typealias Parameters = [String: Any]

    private let repo = "ReactiveX/RxSwift"

    private let events = BehaviorRelay<[Event]>(value: [])
    private let bag = DisposeBag()
    private let eventsFileURL = cachedFileURL("events.plist")
    private let modifiedFileURL = cachedFileURL("modified.txt")

    private let lastModified = BehaviorRelay<NSString?>(value: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = repo

        self.refreshControl = UIRefreshControl()
        let refreshControl = self.refreshControl!

        refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        refreshControl.tintColor = UIColor.darkGray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        let lastModified = try? NSString(contentsOf: modifiedFileURL, encoding: String.Encoding.utf8.rawValue)
        self.lastModified.accept(lastModified)

        refresh()
    }

    @objc func refresh() {
        let eventsArray = (NSArray(contentsOf: eventsFileURL)
            as? [[String: Any]]) ?? []
        events.accept(eventsArray.compactMap(Event.init))
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.fetchEvents(repo: strongSelf.repo)
        }
    }

    func fetchEvents(repo: String) {
        let response = Observable.from(["https://api.github.com/search/repositories?q=language:swift&per_page=5"])
            .map({ URL(string: $0)! })
            .flatMap( {URLSession.shared.rx.json(url: $0)}).map({ (json) -> [String] in
                guard let jsonObject = json as? Parameters else {
                    return []
                }
                guard let allItems = jsonObject["items"] as? [Parameters] else {
                    return []
                }
                return allItems.compactMap({ (item) -> String? in
                    return item["full_name"] as? String
                })
            })
            .flatMap({Observable<String>.from($0)})
            .map({ URL(string: "https://api.github.com/repos/\($0)/events?per_page=10")! })
            .map({ [weak self] url -> URLRequest in
                var request = URLRequest(url: url)
                if let modifiedHeader = self?.lastModified.value {
                    request.addValue(modifiedHeader as String,
                                     forHTTPHeaderField: "Last-Modified")
                }
                return request
            })
            .flatMap { (request) in
                return URLSession.shared.rx.response(request: request)
            }.share(replay: 1, scope: SubjectLifetimeScope.whileConnected)
        response.filter { (response, _) -> Bool in
            return 200..<300 ~= response.statusCode
            }.map { (_, data) -> [Parameters] in
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
                    return []
                }
                guard let results = json as? [Parameters] else {
                    return []
                }
                return results
            }.filter { (json) -> Bool in
                return json.count > 0
            }.map { (json) in
                return json.compactMap(Event.init)
            }.subscribe(onNext: { [weak self] newEvents in
                self?.processEvents(newEvents)
            }).disposed(by: bag)
        response.filter { (response, _) -> Bool in
            return 200..<300 ~= response.statusCode
        }.flatMap { (response, _) -> Observable<NSString> in
            guard let value = response.allHeaderFields["Last-Modified"]  as? NSString else {
                return Observable.empty()
            }
            return Observable.just(value)
        }.subscribe(onNext: { [weak self] modifiedHeader in
            guard let strongSelf = self else {
                return
            }
            strongSelf.lastModified.accept(modifiedHeader)
            try? modifiedHeader.write(to: strongSelf.modifiedFileURL, atomically: true, encoding: String.Encoding.utf8.rawValue)
        }).disposed(by: bag)
    }

    func processEvents(_ newEvents: [Event]) {
        print(newEvents.count)
        var updatedEvents = newEvents + events.value
        print(updatedEvents.count)
        if updatedEvents.count > 50 {
            updatedEvents = Array<Event>(updatedEvents.prefix(upTo: 50))
        }
        let eventArray = updatedEvents.map({$0.dictionary}) as NSArray
        eventArray.write(to: eventsFileURL, atomically: true)
        events.accept(updatedEvents)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
}

extension ActivityController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events.value[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = event.name
        cell.detailTextLabel?.text = event.repo + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
        cell.imageView?.kf.setImage(with: event.imageUrl, placeholder: UIImage(named: "blank-avatar"))
        return cell
    }
}

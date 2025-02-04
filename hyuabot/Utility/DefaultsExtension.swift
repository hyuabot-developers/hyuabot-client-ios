import UIKit
import RxSwift

func observeUserDefaultsStringArray(forKey key: String) -> Observable<[String]> {
    return Observable.create { observer in
        // Initial value emitted
        let initialValue = UserDefaults.standard.stringArray(forKey: key) ?? []
        observer.onNext(initialValue)

        let notificationCenter = NotificationCenter.default
        let notificationName = UserDefaults.didChangeNotification

        let notificationObserver = notificationCenter.addObserver(forName: notificationName, object: nil, queue: .main) { _ in
            let updatedValue = UserDefaults.standard.stringArray(forKey: key) ?? []
            observer.onNext(updatedValue)
        }

        return Disposables.create {
            notificationCenter.removeObserver(notificationObserver)
        }
    }
}

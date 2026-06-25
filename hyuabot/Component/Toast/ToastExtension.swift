import UIKit

extension UIViewController {
    func showToastMessage(image: UIImage?, message: String) {
        let toastView = ToastMessageView(frame: CGRect(x: 20, y: view.frame.height - 150, width: view.frame.width - 40, height: 50))
        view.addSubview(toastView)
        toastView.configure(image: image, message: message)
        UIView.animate(
            withDuration: 3.0,
            delay: 0.0,
            options: [.curveEaseIn, .beginFromCurrentState],
            animations: {
                toastView.alpha = 0.0
            }
        ) { _ in
            toastView.removeFromSuperview()
        }
    }
}

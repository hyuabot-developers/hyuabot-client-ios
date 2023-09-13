import UIKit


extension UIViewController {
    func showToast(message : String, font: UIFont = UIFont.godo(size: 14.0, weight: .regular)) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 100, y: self.view.frame.size.height-125, width: 200, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 3.0, delay: 0.1, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

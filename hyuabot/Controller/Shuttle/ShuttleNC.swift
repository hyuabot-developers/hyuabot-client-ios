import UIKit

class ShuttleNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: ShuttleRealtimeVC())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = .hanyangBlue
        self.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.setNavigationBarHidden(false, animated: false)
    }
}

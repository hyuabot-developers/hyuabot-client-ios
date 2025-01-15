import UIKit

class BusTimetableVC: UIViewController {
    let stopID: Int
    let routes: [Int]
    
    required init(stopID: Int, routes: [Int]) {
        self.stopID = stopID
        self.routes = routes
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

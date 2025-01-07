import UIKit

class ShuttleRealtimeTabVC: UIViewController {
    let stopID: ShuttleStopEnum
    
    required init(stopID: ShuttleStopEnum) {
        self.stopID = stopID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

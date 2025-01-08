import UIKit

class ShuttleTimetableVC: UIViewController {
    private let stopID: String
    private let tags: [String]
    
    init(stopID: String, tags: [String]) {
        self.stopID = stopID
        self.tags = tags
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .systemBackground
    }
}

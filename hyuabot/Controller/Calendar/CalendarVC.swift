import UIKit

class CalendarVC: UIViewController {
    private lazy var calenadrView = {
        let calendarView = UICalendarView()
        calendarView.delegate = self
        calendarView.selectionBehavior = .none
        calendarView.tintColor = .plainButtonText
        return calendarView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        self.view.addSubview(self.calenadrView)
        self.calenadrView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(500)
        }
    }
}

extension CalendarVC: UICalendarViewDelegate {
    
}

import SafariServices
import UIKit

class WebViewVC: UIViewController {
    let url: URL

    required init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logScreenView(.webView)
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true, completion: {
            self.navigationController?.popViewController(animated: false)
        })
    }
}

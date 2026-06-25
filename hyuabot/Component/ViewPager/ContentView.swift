import UIKit

protocol ContentViewDelegate: AnyObject {
    func didMoveToPage(index: Int)
}

class ContentView: UIView {
    var pages: [UIView] = [] {
        didSet { collectionView.reloadData() }
    }

    weak var delegate: ContentViewDelegate?
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout().then {
            $0.scrollDirection = .horizontal
        }
        return UICollectionView(frame: .zero, collectionViewLayout: layout).then {
            $0.showsHorizontalScrollIndicator = false
            $0.isPagingEnabled = true
            $0.backgroundColor = .systemBackground
            $0.register(ContentViewCell.self, forCellWithReuseIdentifier: "ContentViewCell")
            $0.dataSource = self
            $0.delegate = self
        }
    }()

    // MARK: - Initialization

    init(pages: [UIView] = []) {
        self.pages = pages
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func moveToPage(index: Int) {
        guard pages.indices.contains(index) else { return }
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
    }
}

extension ContentView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContentViewCell", for: indexPath) as! ContentViewCell
        guard pages.indices.contains(indexPath.item) else { return cell }
        cell.content = pages[indexPath.item]
        return cell
    }
}

extension ContentView: UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView.frame.width > 0 else { return }
        let index = Int(scrollView.contentOffset.x / scrollView.frame.width)
        guard pages.indices.contains(index) else { return }
        delegate?.didMoveToPage(index: index)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.frame.size
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        0
    }
}

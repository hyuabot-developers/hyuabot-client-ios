import UIKit

protocol ContentViewDelegate: AnyObject {
    func didMoveToPage(index: Int)
}

class ContentView: UIView {
    var pages: [UIView] = [] { didSet { self.collectionView.reloadData() } }
    weak var delegate: ContentViewDelegate?
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout().then {
            $0.scrollDirection = .horizontal
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout).then {
            $0.showsHorizontalScrollIndicator = false
            $0.isPagingEnabled = true
            $0.backgroundColor = .systemBackground
            $0.register(ContentViewCell.self, forCellWithReuseIdentifier: "ContentViewCell")
            $0.dataSource = self
            $0.delegate = self
        }
        return collectionView
    }()
    
    // MARK: - Initialization
    init(pages: [UIView] = []) {
        self.pages = pages
        super.init(frame: .zero)
        self.setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - UI Setup
    private func setupUI() {
        self.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func moveToPage(index: Int) {
        self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
    }
}

extension ContentView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.pages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContentViewCell", for: indexPath) as! ContentViewCell
        cell.content = self.pages[indexPath.item]
        return cell
    }
}

extension ContentView: UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / scrollView.frame.width)
        self.delegate?.didMoveToPage(index: index)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

import UIKit

class NoticeCarouselView: UIView {
    private var notices: [Notice] = []
    private var currentIndex: Int = 0
    private var timer: Timer?
    var onNoticeTapped: ((String) -> Void)?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(NoticeCell.self, forCellWithReuseIdentifier: NoticeCell.reuseIdentifier)
        return collectionView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI(with notices: [Notice]) {
        self.notices = notices
        self.collectionView.reloadData()
        startAutoScroll()
    }
    
    func startAutoScroll() {
        self.stopAutoScroll()
        guard notices.count > 1 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.scrollToNext()
        }
    }
    
    func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }
    
    private func scrollToNext() {
        currentIndex = (currentIndex + 1) % notices.count
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
    }
}

extension NoticeCarouselView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        notices.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoticeCell", for: indexPath) as! NoticeCell
        let notice = notices[indexPath.item]
        cell.setupUI(with: notice)
        cell.onTap = { [weak self] in
            guard notice.url != nil && notice.url?.isEmpty == false else { return }
            self?.onNoticeTapped?(notice.url!)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
}

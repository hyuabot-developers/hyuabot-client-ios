import UIKit

class NoticeCarouselView: UIView {
    private var notices: [Notice] = []
    private var currentIndex: Int = 0
    private var timer: Timer?
    private var manuallyScrolled: Bool = false
    var onNoticeTapped: ((String) -> Void)?
    private let skeletonBar = UIView().then {
        $0.backgroundColor = UIColor.white.withAlphaComponent(0.36)
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(NoticeCell.self, forCellWithReuseIdentifier: NoticeCell.reuseIdentifier)
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
        addSubview(skeletonBar)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        skeletonBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(14)
        }
        setLoading(true)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(with notices: [Notice]) {
        self.notices = notices
        setLoading(false)
        collectionView.reloadData()
        startAutoScroll()
    }

    func setLoading(_ isLoading: Bool) {
        skeletonBar.isHidden = !isLoading
        collectionView.isHidden = isLoading

        if isLoading {
            stopAutoScroll()
            startSkeletonAnimation()
        } else {
            skeletonBar.layer.removeAnimation(forKey: "noticeSkeletonOpacity")
        }
    }

    private func startSkeletonAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.45
        animation.toValue = 1.0
        animation.duration = 0.9
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        skeletonBar.layer.removeAnimation(forKey: "noticeSkeletonOpacity")
        skeletonBar.layer.add(animation, forKey: "noticeSkeletonOpacity")
    }

    func startAutoScroll() {
        stopAutoScroll()
        guard notices.count > 1, !manuallyScrolled else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.scrollToNext()
        }
    }

    func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }

    func resumeAutoScroll() {
        manuallyScrolled = false
        startAutoScroll()
    }

    private func scrollToNext() {
        currentIndex = (currentIndex + 1) % notices.count
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
    }
}

extension NoticeCarouselView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        manuallyScrolled = true
        stopAutoScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = collectionView.bounds.width
        guard pageWidth > 0 else { return }
        currentIndex = Int(round(collectionView.contentOffset.x / pageWidth))
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
            guard notice.url != nil, notice.url?.isEmpty == false else { return }
            self?.onNoticeTapped?(notice.url!)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
}

import UIKit
import SnapKit

protocol TabViewDelegate: AnyObject {
    func didMoveToTab(index: Int)
}

class TabView: UIView {
    enum TabSizeConfiguration {
        case fillEqually(height: CGFloat, spacing: CGFloat = 0)
        case fixed(width: CGFloat, height: CGFloat, spacing: CGFloat = 0)
        
        var height: CGFloat {
            switch self {
            case .fillEqually(let height, _):
                return height
            case .fixed(_, let height, _):
                return height
            }
        }
    }
    
    // MARK: - Attributes
    weak var delegate: TabViewDelegate?
    private var selectedIndex = 0
    private let sizeConfiguration: TabSizeConfiguration
    var tabs: [TabItem] {
        didSet {
            self.collectionView.reloadData()
            guard self.tabs.indices.contains(selectedIndex) else { return }
            self.tabs[selectedIndex].onSelected()
        }
    }
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout().then {
            $0.scrollDirection = .horizontal
            $0.estimatedItemSize = .zero
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout).then {
            $0.backgroundColor = UIColor.hanyangBlue
            $0.register(TabCell.self, forCellWithReuseIdentifier: "TabCell")
            $0.dataSource = self
            $0.delegate = self
            $0.showsHorizontalScrollIndicator = false
        }
        return collectionView
    }()
    
    // MARK: - Initializers
    init(sizeConfiguration: TabSizeConfiguration, tabs: [TabItem] = []) {
        self.sizeConfiguration = sizeConfiguration
        self.tabs = tabs
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var currentIndex: Int { selectedIndex }

    func tabCellView(at index: Int) -> UIView? {
        guard tabs.indices.contains(index) else { return nil }
        return collectionView.cellForItem(at: IndexPath(item: index, section: 0))
    }

    func moveToTab(index: Int) {
        guard self.tabs.indices.contains(index),
              self.tabs.indices.contains(selectedIndex) else { return }
        self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
        self.tabs[selectedIndex].onDeselected()
        self.tabs[index].onSelected()
        self.selectedIndex = index
    }
    
    private func setupUI() {
        self.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (view) -> Void in
            view.edges.equalToSuperview()
        }
    }
}

extension TabView: UICollectionViewDelegateFlowLayout  {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch sizeConfiguration {
        case .fillEqually(let height, let spacing):
            guard !tabs.isEmpty else { return CGSize(width: 0, height: height) }
            let totalWidth = collectionView.frame.width - CGFloat(tabs.count + 1) * spacing
            let width = totalWidth / CGFloat(tabs.count)
            return CGSize(width: width, height: height)
        case .fixed(let width, let height, let spacing):
            return CGSize(width: width - spacing * 2, height: height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch sizeConfiguration {
        case .fillEqually(_, let spacing):
            return spacing
        case .fixed(_, _, let spacing):
            return spacing
        }
    }
}

extension TabView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCell", for: indexPath) as! TabCell
        guard tabs.indices.contains(indexPath.item) else { return cell }
        cell.tabItem = tabs[indexPath.item]
        return cell
    }
}

extension TabView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard tabs.indices.contains(indexPath.item) else { return }
        guard indexPath.item != selectedIndex else { return }
        self.moveToTab(index: indexPath.item)
        self.delegate?.didMoveToTab(index: indexPath.item)
    }
}

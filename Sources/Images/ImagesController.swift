import UIKit
import Photos

class ImagesController: UIViewController, UIViewControllerPreviewingDelegate {

  lazy var dropdownController: DropdownController = self.makeDropdownController()
  lazy var gridView: GridView = self.makeGridView()
  lazy var stackView: StackView = self.makeStackView()
  lazy var infoLabel: UILabel = self.makeInfoLabel()

  var items: [Image] = []
  let library = ImagesLibrary()
  var selectedAlbum: Album?
  let once = Once()
  let cart: Cart

  // MARK: - Init

  public required init(cart: Cart) {
    self.cart = cart
    super.init(nibName: nil, bundle: nil)
    cart.delegates.add(self)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Life cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    setup()
  }

  // MARK: - Setup

  func setup() {
    registerForPreviewing(with: self, sourceView: self.gridView.collectionView)
    view.backgroundColor = UIColor.white

    view.addSubview(gridView)

    addChildViewController(dropdownController)
    gridView.insertSubview(dropdownController.view, belowSubview: gridView.topView)
    dropdownController.didMove(toParentViewController: self)

    [stackView, infoLabel].forEach {
        gridView.bottomView.addSubview($0)
    }

    gridView.g_pinEdges()

    dropdownController.view.g_pin(on: .left)
    dropdownController.view.g_pin(on: .right)
    dropdownController.view.g_pin(on: .height, constant: -40)
    dropdownController.topConstraint = dropdownController.view.g_pin(on: .top,
                                                                     view: gridView.topView, on: .bottom,
                                                                     constant: view.frame.size.height, priority: 999)

    stackView.g_pin(on: .centerY, constant: -4)
    stackView.g_pin(on: .left, constant: 38)
    stackView.g_pin(size: CGSize(width: 56, height: 56))
    
    infoLabel.g_pin(on: .centerY)
    infoLabel.g_pin(on: .left, view: stackView, on: .right, constant: 11)
    infoLabel.g_pin(on: .right, constant: -50)

    gridView.closeButton.addTarget(self, action: #selector(closeButtonTouched(_:)), for: .touchUpInside)
    gridView.doneButton.addTarget(self, action: #selector(doneButtonTouched(_:)), for: .touchUpInside)
    gridView.arrowButton.addTarget(self, action: #selector(arrowButtonTouched(_:)), for: .touchUpInside)
    stackView.addTarget(self, action: #selector(stackViewTouched(_:)), for: .touchUpInside)

    gridView.collectionView.dataSource = self
    gridView.collectionView.delegate = self
    gridView.collectionView.register(ImageCell.self, forCellWithReuseIdentifier: String(describing: ImageCell.self))
  }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //This will show the cell clearly and blur the rest of the screen for our peek.
        guard let indexPath = gridView.collectionView.indexPathForItem(at: location) else { return nil }
        guard let cell = gridView.collectionView.cellForItem(at: indexPath) else { return nil }
        let storyboard = UIStoryboard(name: "ImagePreview", bundle: nil)
        guard let detailVC = storyboard.instantiateViewController(withIdentifier: "ImagePreviewViewController") as? ImagePreviewViewController else {return nil }
        let item = items[(indexPath as NSIndexPath).item]
        detailVC.image = item
        detailVC.isShowingAsPreview = true
        previewingContext.sourceRect = cell.frame
        return detailVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let detailVC = viewControllerToCommit as? ImagePreviewViewController else { return }
        detailVC.isShowingAsPreview = false
        present(detailVC, animated: true, completion: nil)
    }
    
    func findImageAspectFitHeight(pixelWidth: CGFloat, pixelHeight: CGFloat) -> CGFloat {
        var actualHeight : CGFloat = pixelHeight
        var actualWidth : CGFloat = pixelWidth
        
        let maxHeight = UIScreen.main.bounds.height
        let maxWidth = UIScreen.main.bounds.width
        print("RETRIEVED SIZE: Width \(pixelWidth)px, Height: \(pixelHeight)px")
        
        var imgRatio : CGFloat = actualWidth/actualHeight
        let maxRatio : CGFloat = maxWidth/maxHeight
        
        if (actualHeight > maxHeight || actualWidth > maxWidth){
            if(imgRatio < maxRatio){
                //adjust width according to maxHeight
                print("ADJUSTING WIDTH ACCORDING TO HEIGHT")
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if(imgRatio > maxRatio){
                //adjust height according to maxWidth
                print("ADJUSTING HEIGHT ACCORDING TO WIDTH")
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else{
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }else{
            print("Expand with to full width")
            imgRatio = actualWidth / actualHeight
            actualWidth = maxWidth // Use screen width
            actualHeight = imgRatio * maxWidth //Expand height accordingly
        }
            print("NEW SIZE: Width \(actualWidth)px, Height: \(actualHeight)px")
            return actualHeight
    }
    
  // MARK: - Action

  @objc func closeButtonTouched(_ button: UIButton) {
    EventHub.shared.close?()
  }

  @objc func doneButtonTouched(_ button: UIButton) {
    EventHub.shared.doneWithImages?()
  }

  @objc func arrowButtonTouched(_ button: ArrowButton) {
    dropdownController.toggle()
    button.toggle(dropdownController.expanding)
  }

  @objc func stackViewTouched(_ stackView: StackView) {
    EventHub.shared.stackViewTouched?()
  }

  // MARK: - Logic

  func show(album: Album) {
    gridView.arrowButton.updateText(album.collection.localizedTitle ?? "")
    items = album.items
    gridView.collectionView.reloadData()
    gridView.collectionView.g_scrollToTop()
    gridView.emptyView.isHidden = !items.isEmpty
  }

  func refreshSelectedAlbum() {
    if let selectedAlbum = selectedAlbum {
      selectedAlbum.reload()
      show(album: selectedAlbum)
    }
  }

  // MARK: - View

  func refreshView() {
    let hasImages = !cart.images.isEmpty
    gridView.bottomView.g_fade(visible: hasImages)
    gridView.collectionView.g_updateBottomInset(hasImages ? gridView.bottomView.frame.size.height : 0)
  }

  // MARK: - Controls

  func makeDropdownController() -> DropdownController {
    let controller = DropdownController()
    controller.delegate = self
    
    return controller
  }
  
  func makeGridView() -> GridView {
    let view = GridView()
    view.bottomView.alpha = 0
    
    return view
  }

  func makeStackView() -> StackView {
    let view = StackView()

    return view
  }
    func makeInfoLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = Config.Font.Text.regular.withSize(12)
        label.text = "TAP TO EDIT"
        return label
    }
}

extension ImagesController: PageAware {

  func pageDidShow() {
    once.run {
      library.reload {
        self.gridView.loadingIndicator.stopAnimating()
        self.dropdownController.albums = self.library.albums
        self.dropdownController.tableView.reloadData()

        if let album = self.library.albums.first {
          self.selectedAlbum = album
          self.show(album: album)
        }
      }
    }
  }
}

extension ImagesController: CartDelegate {

  func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool) {
    stackView.reload(cart.images, added: true)
    refreshView()

    if newlyTaken {
      refreshSelectedAlbum()
    }
  }

  func cart(_ cart: Cart, didRemove image: Image) {
    stackView.reload(cart.images)
    refreshView()
  }

  func cartDidReload(_ cart: Cart) {
    stackView.reload(cart.images)
    refreshView()
    refreshSelectedAlbum()
  }
}

extension ImagesController: DropdownControllerDelegate {

  func dropdownController(_ controller: DropdownController, didSelect album: Album) {
    selectedAlbum = album
    show(album: album)

    dropdownController.toggle()
    gridView.arrowButton.toggle(controller.expanding)
  }
}

extension ImagesController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  // MARK: - UICollectionViewDataSource

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageCell.self), for: indexPath)
      as! ImageCell
    let item = items[(indexPath as NSIndexPath).item]

    cell.configure(item)
    configureFrameView(cell, indexPath: indexPath)

    return cell
  }

  // MARK: - UICollectionViewDelegateFlowLayout

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

    let size = (collectionView.bounds.size.width - (Config.Grid.Dimension.columnCount - 1) * Config.Grid.Dimension.cellSpacing)
      / Config.Grid.Dimension.columnCount
    return CGSize(width: size, height: size)
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let item = items[(indexPath as NSIndexPath).item]

    if cart.images.contains(item) {
      cart.remove(item)
    } else {
      if Config.Camera.imageLimit == 0 || Config.Camera.imageLimit > cart.images.count{
        cart.add(item)
      }
    }

    configureFrameViews()
  }

  func configureFrameViews() {
    for case let cell as ImageCell in gridView.collectionView.visibleCells {
      if let indexPath = gridView.collectionView.indexPath(for: cell) {
        configureFrameView(cell, indexPath: indexPath)
      }
    }
  }

  func configureFrameView(_ cell: ImageCell, indexPath: IndexPath) {
    let item = items[(indexPath as NSIndexPath).item]

    if let index = cart.images.index(of: item) {
      cell.frameView.g_quickFade()
      cell.frameView.label.text = "\(index + 1)"
    } else {
      cell.frameView.alpha = 0
    }
  }
}

class ImagePreviewViewController: UIViewController {
    var isShowingAsPreview: Bool = false
    var image: Image!
    @IBOutlet var imageView: UIImageView!
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.modalTransitionStyle = .crossDissolve
        image.resolve { (UIImage) in
            self.imageView.image = UIImage
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.isShowingAsPreview {
            let photoWidth = image.asset.pixelWidth
            let photoHeight = image.asset.pixelHeight
            let viewWidth = self.view.frame.size.width
            let widthAspectRatio = CGFloat(photoWidth) / viewWidth
            let aspectHeight = CGFloat(photoHeight) / widthAspectRatio
            let preferredContentHeight = aspectHeight > 460 ? 460 : aspectHeight
            self.preferredContentSize = CGSize(width: 0, height: preferredContentHeight)
            self.imageView.contentMode = .scaleAspectFill
        }else{
            self.imageView.contentMode = .scaleAspectFit
        }
    }
}

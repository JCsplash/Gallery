import UIKit
import Gallery
import Lightbox
import AVFoundation
import AVKit

class ViewController: UIViewController, LightboxControllerDismissalDelegate, GalleryControllerDelegate {
  func galleryController(_ controller: GalleryController, capturedPhoto image: UIImage) {
    return
  }
  
  func galleryController(_ controller: GalleryController, capturedVideo videoURL: URL) {
    return
  }
  

  var button: UIButton!
  var gallery: GalleryController!
  let editor: VideoEditing = VideoEditor()
  let maxImageSize = CGSize(width: 2048.0, height: 2048.0) //for retrieving images from photos app

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.white

    Gallery.Config.VideoEditor.savesEditedVideoToLibrary = true

    button = UIButton(type: .system)
    button.frame.size = CGSize(width: 200, height: 50)
    button.setTitle("Open Gallery", for: UIControlState())
    button.addTarget(self, action: #selector(buttonTouched(_:)), for: .touchUpInside)

    view.addSubview(button)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    button.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
  }

  func buttonTouched(_ button: UIButton) {
    gallery = GalleryController()
    gallery.delegate = self

    present(gallery, animated: true, completion: nil)
  }

  // MARK: - LightboxControllerDismissalDelegate

  func lightboxControllerWillDismiss(_ controller: LightboxController) {

  }

  // MARK: - GalleryControllerDelegate

  func galleryControllerDidCancel(_ controller: GalleryController) {
    controller.dismiss(animated: true, completion: nil)
    gallery = nil
  }

  func galleryController(_ controller: GalleryController, didSelectMedia images: [Image], video: Video?) {
    controller.dismiss(animated: true, completion: nil)
    gallery = nil
  }
  func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
    return
  }
  func galleryController(_ controller: GalleryController, requestVideoLightbox video: Video) {
    return
  }

  // MARK: - Helper

  func showLightbox(images: [UIImage]) {
    guard images.count > 0 else {
      return
    }

    let lightboxImages = images.map({ LightboxImage(image: $0) })
    let lightbox = LightboxController(images: lightboxImages, startIndex: 0)
    lightbox.dismissalDelegate = self

    gallery.present(lightbox, animated: true, completion: nil)
  }
}


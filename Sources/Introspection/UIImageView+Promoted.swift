import Foundation
import UIKit

extension UIImageView {

  convenience init(frame: CGRect, asyncImageURLString: String) {
    self.init(frame: frame)
    if let url = URL(string: asyncImageURLString) {
      URLSession.shared.dataTask(with: url) { data, response, error in
        guard error == nil else { return }
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          if let data = try? Data(contentsOf: url) {
            self.image = UIImage(data: data)
          }
        }
      }.resume()
    }
    self.image = UIImage(color: .gray, size: frame.size)
  }
}

private extension UIImage {

  convenience init?(color: UIColor, size: CGSize) {
    let rect = CGRect(origin: .zero, size: size)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    color.setFill()
    UIRectFill(rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    guard let cgImage = image?.cgImage else { return nil }
    self.init(cgImage: cgImage)
  }
}

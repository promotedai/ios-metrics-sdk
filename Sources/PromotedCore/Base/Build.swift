import Foundation

struct Build {
  /// Version of Promoted library.
  static let libVersion: String = {
    guard let path = bundle?.path(forResource: "Version", ofType: "txt") else {
      return "Unknown"
    }
    return (
      try? String(contentsOfFile: path)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    ) ?? "Unknown"
  } ()

  private static let bundle: Bundle? = {
    #if COCOAPODS
      guard let libBundleURL = Bundle.main.url(forResource: "PromotedCore", withExtension: "bundle") else {
        return nil
      }
      return Bundle(url: libBundleURL)
    #else
      return Bundle.module
    #endif
  } ()
}

import Foundation

/** Provides build versions for platform app and Promoted SDK. */
protocol BuildInfo {
  /// Version of platform app.
  var platformAppVersion: String { get }

  /// Version of Promoted library.
  var promotedMobileSdkVersion: String { get }
}

protocol BuildInfoSource {
  var buildInfo: BuildInfo { get }
}

final class IOSBuildInfo: BuildInfo {

  private(set) lazy var platformAppVersion: String = {
    let appVersion = Bundle.main.object(
      forInfoDictionaryKey: "CFBundleShortVersionString"
    ) ?? "Unknown"
    let buildNumber = Bundle.main.object(
      forInfoDictionaryKey: "CFBundleVersion"
    ) ?? "Unknown"
    return "\(appVersion) build \(buildNumber)"
  } ()

  private(set) lazy var promotedMobileSdkVersion: String = {
    guard let path = bundle?.path(
      forResource: "Version",
      ofType: "txt"
    ) else {
      return "Unknown"
    }
    return (
      try? String(contentsOfFile: path)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    ) ?? "Unknown"
  } ()

  private var bundle: Bundle? {
    #if COCOAPODS
      guard let libBundleURL = Bundle.main.url(
        forResource: "PromotedCore",
        withExtension: "bundle"
      ) else {
        return nil
      }
      return Bundle(url: libBundleURL)
    #else
      return Bundle.module
    #endif
  }
}

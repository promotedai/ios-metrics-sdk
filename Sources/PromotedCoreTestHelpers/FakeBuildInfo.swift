import Foundation

@testable import PromotedCore

final class FakeBuildInfo: BuildInfo {
  var platformAppVersion: String { "3.1.4" }

  var promotedMobileSDKVersion: String { "1.0.99" }
}

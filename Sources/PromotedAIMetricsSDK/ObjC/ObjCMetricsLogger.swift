import Foundation
import Protobuf

#if canImport(GTMSessionFetcherCore)
import GTMSessionFetcherCore
#elseif canImport(GTMSessionFetcher)
import GTMSessionFetcher
#else
#error("Can't import GTMSessionFetcher")
#endif

#if canImport(SchemaProtosObjC)
import SchemaProtosObjC
#endif

@objc(PAMetricsLogger)
public class ObjCMetricsLogger: NSObject {
  @objc public convenience init(customizer: ObjCMetricsCustomizer) {
    self.init(customizer: customizer, fetcherService: GTMSessionFetcherService())
  }

  @objc public init(customizer: ObjCMetricsCustomizer,
              fetcherService: GTMSessionFetcherService) {
  }

  @objc public func logSessionStart(clientMessage: GPBMessage? = nil) {
  }

  @objc public func logImpression(clientMessage: GPBMessage? = nil) {
  }
  
  @objc public func logClick(clientMessage: GPBMessage? = nil) {
  }
  
  @objc public func flush() {
  }
}

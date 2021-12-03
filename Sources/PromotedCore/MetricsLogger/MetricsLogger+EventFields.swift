import Foundation
import SwiftProtobuf

extension MetricsLogger {
  func clientPositionMessage(
    _ collectionInteraction: CollectionInteraction?
  ) -> Event_IndexPath? {
    guard
      config.eventsIncludeClientPositions,
      let collectionInteraction = collectionInteraction
    else { return nil }
    var clientPosition = Event_IndexPath()
    clientPosition.index = collectionInteraction.indexPath
    return clientPosition
  }

  func deviceMessage() -> Common_Device {
    if cachedDeviceMessage == nil {
      var device = Common_Device()
      device.deviceType = deviceInfo.deviceType.protoValue
      device.brand = deviceInfo.brand
      device.manufacturer = deviceInfo.manufacturer
      device.identifier = deviceInfo.modelName
      device.osVersion = deviceInfo.osVersion
      device.platformAppVersion = buildInfo.platformAppVersion
      device.promotedMobileSdkVersion = buildInfo.promotedMobileSDKVersion
      let (width, height) = deviceInfo.screenSizePx
      device.screen.size.width = width
      device.screen.size.height = height
      device.screen.scale = deviceInfo.screenScale
      cachedDeviceMessage = device
    }
    return cachedDeviceMessage!
  }

  func localeMessage() -> Common_Locale {
    if cachedLocaleMessage == nil {
      var locale = Common_Locale()
      locale.languageCode = deviceInfo.languageCode
      locale.regionCode = deviceInfo.regionCode
      cachedLocaleMessage = locale
    }
    return cachedLocaleMessage!
  }

  func propertiesMessage(_ message: Message?) -> Common_Properties? {
    do {
      if let message = message {
        var dataMessage = Common_Properties()
        dataMessage.structBytes = try message.serializedData()
        return dataMessage
      }
    } catch {
      handleExecutionError(
        MetricsLoggerError.propertiesSerializationError(
          underlying: error
        )
      )
    }
    return nil
  }

  func timingMessage() -> Common_Timing {
    var timing = Common_Timing()
    timing.clientLogTimestamp = UInt64(clock.nowMillis)
    return timing
  }

  func userInfoMessage() -> Common_UserInfo {
    var userInfo = Common_UserInfo()
    if let id = userID.stringValue { userInfo.userID = id }
    if let id = logUserID { userInfo.logUserID = id }
    return userInfo
  }
}

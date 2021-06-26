Pod::Spec.new do |s|
  s.name             = 'PromotedAIMetricsSDK'
  s.version          = File.read('Sources/PromotedCore/Resources/Version.txt')
  s.summary          = 'iOS client library for Promoted.ai metrics tracking.'

  s.description      = <<-DESC
  iOS client library for Promoted.ai metrics tracking.
  Provided as both a Cocoapod and Swift Package.
  DESC

  s.homepage         = 'https://github.com/promotedai/ios-metrics-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Yu-Hong Wang' => 'yu-hong@promoted.ai' }
  s.source           = {
    :git => 'https://github.com/promotedai/ios-metrics-sdk.git',
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.3'

  # By default we bring in GTMSessionFetcher for networking.
  # If you provide your own network implementation, depend on
  # 'PromotedAIMetricsSDK/Core' instead.
  s.default_subspecs = 'Metrics'

  s.subspec 'Core' do |core|
    core.source_files = ['Sources/PromotedCore/**/*.{h,m,swift}']
    core.dependency 'SwiftProtobuf', '~> 1.15.0'
    core.resource_bundles = {
      "PromotedCore" => ['Sources/PromotedCore/Resources/*']
    }
  end

  s.subspec 'Fetcher' do |fetcher|
    fetcher.source_files = ['Sources/PromotedFetcher/**/*.{h,m,swift}']
    fetcher.dependency 'GTMSessionFetcher/Core', '~> 1.5.0'
    fetcher.dependency 'PromotedAIMetricsSDK/Core'
  end

  s.subspec 'Metrics' do |metrics|
    metrics.source_files = ['Sources/PromotedMetrics/**/*.{h,m,swift}']
    metrics.dependency 'PromotedAIMetricsSDK/Core'
    metrics.dependency 'PromotedAIMetricsSDK/Fetcher'
  end

  analytics_xcconfig = {
    'USER_HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Firebase/CoreOnly/Sources"',
    'FRAMEWORK_SEARCH_PATHS' => '"${PODS_XCFRAMEWORKS_BUILD_DIR}/FirebaseAnalytics" "${PODS_XCFRAMEWORKS_BUILD_DIR}/GoogleUtilities" "${PODS_XCFRAMEWORKS_BUILD_DIR}/nanopb"',
    'OTHER_LDFLAGS' => '-framework "FirebaseAnalytics" -framework "GoogleUtilities" -framework "nanopb"'
  }

  s.subspec 'FirebaseAnalytics' do |a|
    a.source_files = ['Sources/PromotedFirebaseAnalytics/**/*.{h,m,swift}']
    a.dependency 'Firebase/Analytics', '~> 7.11.0'
    a.dependency 'PromotedAIMetricsSDK/Core'
    a.pod_target_xcconfig = analytics_xcconfig
  end

  s.subspec 'FirebaseAnalyticsWithoutAdIdSupport' do |a|
    a.source_files = ['Sources/PromotedFirebaseAnalytics/**/*.{h,m,swift}']
    a.dependency 'Firebase/AnalyticsWithoutAdIdSupport', '~> 7.11.0'
    a.dependency 'PromotedAIMetricsSDK/Core'
    analytics_without_ad_id_xcconfig = analytics_xcconfig
    analytics_without_ad_id_xcconfig['OTHER_LDFLAGS'] = analytics_xcconfig['OTHER_LDFLAGS'] + ' -framework "GoogleAppMeasurementWithoutAdIdSupport"'
    a.pod_target_xcconfig = analytics_without_ad_id_xcconfig
  end
end

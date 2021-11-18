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

  # The Firebase targets all need extra xcconfig bits to build.

  # Header search paths are needed at compile time in order to
  # resolve the `import Firebase` module.
  firebase_header_search_paths = '"${PODS_ROOT}/Firebase/CoreOnly/Sources"'

  # Linker flags are needed when the host app has no other
  # Firebase dependencies.
  analytics_ldflags = '-framework "FirebaseAnalytics" -framework "GoogleUtilities" -framework "nanopb"'

  s.subspec 'FirebaseAnalytics' do |a|
    a.source_files = ['Sources/PromotedFirebaseAnalytics/**/*.{h,m,swift}']
    a.dependency 'Firebase/Analytics', '~> 7.9.0'
    a.dependency 'PromotedAIMetricsSDK/Core'

    a.pod_target_xcconfig = {
      'USER_HEADER_SEARCH_PATHS' => firebase_header_search_paths,
      'OTHER_LDFLAGS' => analytics_ldflags
    }
  end

  s.subspec 'FirebaseAnalyticsWithoutAdIdSupport' do |a|
    a.source_files = ['Sources/PromotedFirebaseAnalytics/**/*.{h,m,swift}']
    a.dependency 'Firebase/AnalyticsWithoutAdIdSupport', '~> 7.11.0'
    a.dependency 'PromotedAIMetricsSDK/Core'

    # Linker flags are needed when the host app has no other
    # Firebase dependencies.
    analytics_noadid_ldflags = analytics_ldflags + ' -framework "GoogleAppMeasurementWithoutAdIdSupport"'

    a.pod_target_xcconfig = {
      'USER_HEADER_SEARCH_PATHS' => firebase_header_search_paths,
      'OTHER_LDFLAGS' => analytics_noadid_ldflags
    }
  end

  s.subspec 'FirebaseRemoteConfig' do |rc|
    rc.source_files = ['Sources/PromotedFirebaseRemoteConfig/**/*.{h,m,swift}']
    rc.dependency 'Firebase/RemoteConfig', '~> 7.9.0'
    rc.dependency 'PromotedAIMetricsSDK/Core'

    # Linker flags are needed when the host app has no other
    # Firebase dependencies.
    remote_config_ldflags = '-framework "FirebaseRemoteConfig" -framework "FirebaseCore"'

    # Silences a Firebase warning to allow `pod lib lint` to pass.
    remote_config_gcc_defs = 'FIREBASE_ANALYTICS_SUPPRESS_WARNING=1'

    rc.pod_target_xcconfig = {
      'USER_HEADER_SEARCH_PATHS' => firebase_header_search_paths,
      'GCC_PREPROCESSOR_DEFINITIONS' => remote_config_gcc_defs,
      'OTHER_LDFLAGS' => remote_config_ldflags
    }

    # Although `user_target_xcconfig` is discouraged, need
    # this for `pod lib lint` to pass.
    rc.user_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => remote_config_gcc_defs
    }
  end
end

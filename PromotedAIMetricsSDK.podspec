# Run `pod lib lint PromotedAIMetricsSDK.podspec' before submitting.
#
# https://guides.cocoapods.org/syntax/podspec.html

Pod::Spec.new do |s|
  s.name             = 'PromotedAIMetricsSDK'
  s.version          = ENV['LIB_VERSION'] || '0.3.1'
  s.summary          = 'iOS client library for Promoted.ai metrics tracking.'
  
  s.description      = <<-DESC
  iOS client library for Promoted.ai metrics tracking.
  Provided as both a Cocoapod and Swift Package.
  DESC
  
  s.homepage         = 'https://github.com/promotedai/ios-metrics-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Yu-Hong Wang' => 'yu-hong@promoted.ai' }
  s.source           = { :git => 'https://github.com/promotedai/ios-metrics-sdk.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.2'
  
  # By default we bring in GTMSessionFetcher for networking.
  # If you provide your own network implementation, depend on
  # 'PromotedAIMetricsSDK/Core' instead.
  s.default_subspecs = 'Fetcher'

  s.subspec 'Core' do |core|
    core.source_files = ['Sources/PromotedAIMetricsSDK/**/*.{h,m,swift}']
    core.dependency 'SwiftProtobuf', '~> 1.15.0'
  end
  
  s.subspec 'Fetcher' do |fetcher|
    fetcher.source_files = ['Sources/Fetcher/**/*.{h,m,swift}']
    fetcher.dependency 'GTMSessionFetcher/Core', '~> 1.5.0'
    fetcher.dependency 'PromotedAIMetricsSDK/Core'
  end
end

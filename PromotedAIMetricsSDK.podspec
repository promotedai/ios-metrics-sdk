# Be sure to run `pod lib lint PromotedAIMetricsSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# https://guides.cocoapods.org/syntax/podspec.html

Pod::Spec.new do |s|
  s.name             = 'PromotedAIMetricsSDK'
  s.version          = '0.1.1'
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
  
  s.source_files = ['Sources/PromotedAIMetricsSDK/**/*.{h,m,swift}']
  s.swift_version = '5.2'

  s.dependency 'GTMSessionFetcher/Core', '~> 1.5.0'
  s.dependency 'SwiftProtobuf', '~> 1.15.0'
end

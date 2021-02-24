# Be sure to run `pod lib lint PromotedAIMetricsSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# https://guides.cocoapods.org/syntax/podspec.html

Pod::Spec.new do |s|
  s.name             = 'PromotedAIMetricsSDK'
  s.version          = '0.0.1'
  s.summary          = 'iOS client library for Promoted.ai metrics tracking.'
  
  s.description      = <<-DESC
  iOS client library for Promoted.ai metrics tracking.
  Provided as both a Cocoapod and Swift Package. Only use the Cocoapod if you
  require integration with Objective C Protobufs.
  DESC
  
  s.homepage         = 'https://github.com/promotedai/ios-metrics-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Yu-Hong Wang' => 'yu-hong@promoted.ai' }
  s.source           = { :git => 'https://github.com/promotedai/ios-metrics-sdk.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '12.0'
  
  s.source_files = [
    'Sources/PromotedAIMetricsSDK/**/*.{h,m,swift}']
  
  s.subspec 'SchemaProtos' do |p|
    p.source_files = [
      'Sources/SchemaProtos/objc/**/*.{h,m}']
    p.public_header_files = [
      'Sources/SchemaProtos/objc/headers/*.h']
    p.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => 'GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1 '}
    p.xcconfig = {
      'USER_HEADER_SEARCH_PATHS' => '"Sources/SchemaProtos/objc"'}
  end

  s.dependency 'GTMSessionFetcher', '~> 1.5.0'
  s.dependency 'Protobuf', '~> 3.9.2'
  s.dependency 'SwiftProtobuf', '~> 1.15.0'
end

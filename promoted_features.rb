# Extra features that can be enabled for a CocoaPods project.
# Promoted includes debugging and introspection tools that you may wish
# to include in internal, non-debug builds, but not in release. These
# functions allow you to specify which build targets in which to include
# these features, to guarantee that they don't appear in release builds.

require 'pp'

def _use_promoted_build_flag(installer, build_configurations: [], build_flag: '')
  installer.pods_project.targets.each do |target|
    next unless target.name == 'PromotedAIMetricsSDK' or target.name == 'react-native-metrics'
    target.build_configurations.each do |config|
      next unless build_configurations.include? config.name
      config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['$(inherited)']
      config.build_settings['OTHER_SWIFT_FLAGS'] << '-D'
      config.build_settings['OTHER_SWIFT_FLAGS'] << build_flag
    end
  end
end

# Call this in your Podfile to enable Promoted error handling in the
# specified build configurations. For example:
# ```
# target 'myapp' do
#   post_install do |installer|
#     # Enables error handling in build config 'InternalBuild'
#     use_promoted_error_handling(
#       installer,
#       build_configurations: ['InternalBuild']
#     )
#   end
# end
# ```
def use_promoted_error_handling(installer, build_configurations: [])
  _use_promoted_build_flag(
    installer,
    build_configurations: build_configurations,
    build_flag: 'PROMOTED_ERROR_HANDLING'
  )
end

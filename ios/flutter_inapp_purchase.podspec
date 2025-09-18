#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_inapp_purchase'
  s.version          = '0.0.1'
  s.summary          = 'In App Purchase plugin for flutter. This project has been forked by react-native-iap and we are willing to share same experience with that on react-native.'
  s.description      = <<-DESC
In App Purchase plugin for flutter. This project has been forked by react-native-iap and we are willing to share same experience with that on react-native.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.swift'
  s.dependency 'Flutter'
  # Use OpenIAP Apple native module (via CocoaPods)
  # Pin exactly 1.1.12 to avoid unexpected updates
  s.dependency 'openiap', '1.1.12'
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.5'
  
  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule',
    'VALID_ARCHS' => 'arm64 x86_64',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end

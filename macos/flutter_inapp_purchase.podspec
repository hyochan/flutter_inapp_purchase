#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
require 'json'
require 'pathname'

podspec_dir = Pathname.new(__dir__).realpath
versions_path = podspec_dir.join('..', 'openiap-versions.json')
openiap_versions = JSON.parse(File.read(versions_path))

Pod::Spec.new do |s|
  s.name             = 'flutter_inapp_purchase'
  s.version          = '0.0.1'
  s.summary          = 'In App Purchase plugin for flutter. This project has been forked by react-native-iap and we are willing to share same experience with that on react-native.'
  s.description      = <<-DESC
In App Purchase plugin for flutter. This project has been forked by react-native-iap and we are willing to share same experience with that on react-native.
                       DESC
  s.homepage         = 'https://github.com/hyochan/flutter_inapp_purchase'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hyo Chan Jang' => 'hyo@hyo.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.swift'
  s.dependency 'FlutterMacOS'
  # Use OpenIAP Apple native module (via CocoaPods)
  s.dependency 'openiap', openiap_versions['apple']

  s.osx.deployment_target = '14.0'
  s.swift_version = '5.5'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }
end

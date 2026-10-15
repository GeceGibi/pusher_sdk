#
# NSE / native-only. Separate pod so CocoaPods does not emit a second
# pusher.framework beside the Flutter plugin target (archive conflict).
#
Pod::Spec.new do |s|
  s.name             = 'PusherStats'
  s.version          = '0.0.1'
  s.summary          = 'Pusher notification receipts (no Flutter; for NSE)'
  s.description      = <<-DESC
Native hello and receipt helpers without Flutter.framework. Use this pod in a
Notification Service Extension. Runner should use the pusher plugin pod.
                       DESC
  s.homepage         = 'https://github.com/GeceGibi/pusher_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pusher' => 'pusher@localhost' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.0'
  s.module_name      = 'PusherStats'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  s.source_files = 'Sources/PusherStats/**/*.{swift,h,m}'
  s.resource_bundles = {
    'PusherStats_Privacy' => ['Sources/PusherStats/PrivacyInfo.xcprivacy']
  }
end

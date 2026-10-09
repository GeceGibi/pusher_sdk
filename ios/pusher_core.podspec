#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
# NSE / native-only. Separate pod name so CocoaPods does not emit a second
# `pusher.framework` beside the Flutter plugin target (archive conflict).
#
Pod::Spec.new do |s|
  s.name             = 'pusher_core'
  s.version          = '0.10.0'
  s.summary          = 'Pusher native core (no Flutter; for NSE)'
  s.description      = <<-DESC
Native hello / receipt helpers without Flutter.framework. Use this pod in a
Notification Service Extension. Runner should use the `pusher` plugin pod.
                       DESC
  s.homepage         = 'https://github.com/GeceGibi/pusher_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pusher' => 'pusher@localhost' }
  s.source           = { :path => '.' }
  s.platform = :ios, '15.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  s.source_files = [
    'pusher/Sources/pusher/PusherLog.swift',
    'pusher/Sources/pusher/PusherConfig.swift',
    'pusher/Sources/pusher/PusherClient.swift',
    'pusher/Sources/pusher/PusherHmac.swift',
    'pusher/Sources/pusher/PusherStats.swift',
  ]
end

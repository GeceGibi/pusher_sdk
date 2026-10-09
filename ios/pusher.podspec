#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'pusher'
  s.version          = '0.6.0'
  s.summary          = 'Native stats client for stats.pusher.tr'
  s.description      = <<-DESC
Device hello and notification receipts for Pusher stats.
                       DESC
  s.homepage         = 'https://github.com/GeceGibi/pusher_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pusher' => 'dev@pusher.tr' }
  s.source           = { :path => '.' }
  s.platform = :ios, '15.0'
  s.swift_version = '5.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  # Runner gets MethodChannel bridge. NSE must use only `pusher/core`
  # (no Flutter.framework in app extensions).
  s.default_subspecs = 'flutter'

  s.subspec 'core' do |ss|
    ss.source_files = [
      'pusher/Sources/pusher/PusherLog.swift',
      'pusher/Sources/pusher/PusherConfig.swift',
      'pusher/Sources/pusher/PusherClient.swift',
      'pusher/Sources/pusher/PusherHmac.swift',
      'pusher/Sources/pusher/PusherStats.swift',
    ]
  end

  s.subspec 'flutter' do |ss|
    ss.dependency 'Flutter'
    ss.dependency 'pusher/core'
    ss.source_files = 'pusher/Sources/pusher/PusherPlugin.swift'
  end
end

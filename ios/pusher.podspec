#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'pusher'
  s.version          = '0.3.0'
  s.summary          = 'Native stats client for stats.pusher.tr'
  s.description      = <<-DESC
Device hello and notification receipts for Pusher stats.
                       DESC
  s.homepage         = 'https://github.com/GeceGibi/pusher_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pusher' => 'dev@pusher.tr' }
  s.source           = { :path => '.' }
  s.source_files = 'pusher/Sources/pusher/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

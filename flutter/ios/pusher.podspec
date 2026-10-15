#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'pusher'
  s.version          = '1.0.2'
  s.summary          = 'Pusher mobile SDK Flutter plugin'
  s.description      = <<-DESC
Flutter plugin bridge for Pusher native hello and notification receipts.
                       DESC
  s.homepage         = 'https://github.com/GeceGibi/pusher_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pusher' => 'pusher@localhost' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  s.dependency 'Flutter'
  s.dependency 'PusherStats', '~> 1.0.2'

  s.source_files = 'Classes/**/*'
end

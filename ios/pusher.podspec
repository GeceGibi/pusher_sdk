#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'pusher'
  s.version          = '0.10.0'
  s.summary          = 'Pusher mobile SDK (native hello / receipts)'
  s.description      = <<-DESC
Native device hello and notification receipts for the Pusher Flutter plugin.
                       DESC
  s.homepage         = 'https://github.com/GeceGibi/pusher_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pusher' => 'pusher@localhost' }
  s.source           = { :path => '.' }
  s.platform = :ios, '15.0'
  s.swift_version = '5.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  # Single product for Runner. NSE must depend on `pusher_core` (separate pod
  # name) — a `pusher/core` subspec collides on `pusher.framework` at archive.
  s.dependency 'Flutter'
  s.source_files = 'pusher/Sources/pusher/**/*.swift'
end

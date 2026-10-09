Pod::Spec.new do |s|
  s.name             = 'pusher_sdk'
  s.version          = '0.2.0'
  s.summary          = 'Native stats client for stats.pusher.tr'
  s.description      = 'Device hello and notification receipts for Pusher stats.'
  s.homepage         = 'https://github.com/GeceGibi/pusher_sdk'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Pusher' => 'dev@pusher.tr' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end

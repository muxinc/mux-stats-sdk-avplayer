Pod::Spec.new do |s|
  s.name             = 'Mux-Stats-AVPlayer'

  s.version          = '4.0.0'
  s.source           = { :git => 'https://github.com/muxinc/mux-stats-sdk-avplayer.git',
                         :tag => "v#{s.version}" }
  s.module_name      = 'MUXSDKStats'

  s.summary          = 'The Mux Stats SDK'
  s.description      = 'The Mux stats SDK connect with AVPlayer to performance analytics and QoS monitoring for video.'

  s.homepage         = 'https://mux.com'
  s.social_media_url = 'https://twitter.com/muxhq'

  s.license          = 'Apache 2.0'
  s.author           = { 'Mux' => 'ios-sdk@mux.com' }

  s.dependency 'Mux-Stats-Core', '4.6.0'

  s.ios.deployment_target = '12.0'
  s.ios.frameworks = 'AVKit', 'AVFoundation', 'SystemConfiguration', 'CoreMedia'

  s.tvos.deployment_target = '12.0'
  s.tvos.frameworks = 'AVKit', 'AVFoundation', 'SystemConfiguration', 'CoreMedia'

  s.source_files = 'Sources/MUXSDKStatsObjc/**/*'
  s.exclude_files = 'Sources/MUXSDKStatsObjc/include/**/*'
end

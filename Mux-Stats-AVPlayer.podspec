Pod::Spec.new do |s|
  s.name             = 'Mux-Stats-AVPlayer'

  s.version          = '4.6.0'
  s.source           = { :git => 'https://github.com/muxinc/mux-stats-sdk-avplayer.git',
                         :tag => "v#{s.version}" }

  s.summary          = 'The Mux Stats SDK'
  s.description      = 'The Mux stats SDK connect with AVPlayer to performance analytics and QoS monitoring for video.'

  s.homepage         = 'https://mux.com'
  s.social_media_url = 'https://twitter.com/muxhq'

  s.license          = 'Apache 2.0'
  s.author           = { 'Mux' => 'ios-sdk@mux.com' }

  s.dependency 'Mux-Stats-Core', '~> 5.4.0'

  s.frameworks = 'AVKit', 'AVFoundation', 'SystemConfiguration', 'CoreMedia'

  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'

  s.module_name = 'MUXSDKStats'
  s.source_files = 'Sources/MUXSDKStats/**/*.{h,m}'
  s.public_header_files = 'Sources/MUXSDKStats/include/*.h'
  s.project_header_files = 'Sources/MUXSDKStats/*.h'
end

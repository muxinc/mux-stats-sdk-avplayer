Pod::Spec.new do |s|
  s.name             = 'Mux-Stats-AVPlayer'

  s.version          = '1.1.3'
  s.source           = { :git => 'https://github.com/muxinc/mux-stats-sdk-avplayer.git',
                         :tag => "v#{s.version}" }

  s.summary          = 'The Mux Stats SDK'
  s.description      = 'The Mux stats SDK connect with AVPlayer to performance analytics and QoS monitoring for video.'

  s.homepage         = 'https://mux.com'
  s.social_media_url = 'https://twitter.com/muxhq'

  s.license          = 'Apache 2.0'
  s.author           = { 'Mux' => 'ios-sdk@mux.com' }

  s.dependency 'Mux-Stats-Core', '~>2.1'


  s.ios.deployment_target = '8.0'
  s.ios.vendored_frameworks = 'Frameworks/iOS/fat/MUXSDKStats.framework'
  # s.ios.source_files = 'MUXSDKStats/MUXSDKStats/*.{h,m}'
  s.ios.frameworks = 'AVKit', 'AVFoundation'

  s.tvos.deployment_target = '9.0'
  s.tvos.vendored_frameworks = 'Frameworks/tvOS/fat/MUXSDKStatsTv.framework'
  # s.tvos.source_files = 'MUXSDKStats/MUXSDKStatsTv/*.{h,m}'
  s.tvos.frameworks = 'AVKit', 'AVFoundation'
end

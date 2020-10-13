Pod::Spec.new do |s|
  s.name             = 'Mux-Stats-AVPlayer'

  s.version          = '1.7.0'
  s.source           = { :git => 'https://github.com/muxinc/mux-stats-sdk-avplayer.git',
                         :tag => "v#{s.version}" }

  s.summary          = 'The Mux Stats SDK'
  s.description      = 'The Mux stats SDK connect with AVPlayer to performance analytics and QoS monitoring for video.'

  s.homepage         = 'https://mux.com'
  s.social_media_url = 'https://twitter.com/muxhq'

  s.license          = 'Apache 2.0'
  s.author           = { 'Mux' => 'ios-sdk@mux.com' }

  s.dependency 'Mux-Stats-Core', '~>2.4'

  s.ios.deployment_target = '9.0'
  s.ios.vendored_frameworks = 'Frameworks/iOS/fat/MUXSDKStats.framework'
  s.ios.frameworks = 'AVKit', 'AVFoundation'

  s.tvos.deployment_target = '9.0'
  s.tvos.vendored_frameworks = 'Frameworks/tvOS/fat/MUXSDKStatsTv.framework'
  s.tvos.frameworks = 'AVKit', 'AVFoundation'
end

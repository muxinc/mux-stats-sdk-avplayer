Pod::Spec.new do |s|
  s.name             = 'Mux-Stats-AVPlayer'

  s.version          = '2.0.2'
  s.source           = { :git => 'https://github.com/muxinc/mux-stats-sdk-avplayer.git',
                         :tag => "v#{s.version}" }

  s.summary          = 'The Mux Stats SDK'
  s.description      = 'The Mux stats SDK connect with AVPlayer to performance analytics and QoS monitoring for video.'

  s.homepage         = 'https://mux.com'
  s.social_media_url = 'https://twitter.com/muxhq'

  s.license          = 'Apache 2.0'
  s.author           = { 'Mux' => 'ios-sdk@mux.com' }

  s.dependency 'Mux-Stats-Core', '~>3.0'

  s.ios.deployment_target = '9.0'
  s.ios.vendored_frameworks = 'XCFramework/MUXSDKStats.xcframework'
  s.ios.frameworks = 'AVKit', 'AVFoundation'

  s.tvos.deployment_target = '9.0'
  s.tvos.vendored_frameworks = 'XCFramework/MUXSDKStats.xcframework'
  s.tvos.frameworks = 'AVKit', 'AVFoundation'

  # if the use_frameworks! declaration is set in the Podfile, the Pod should be built as a static framework
  s.static_framework = true
end

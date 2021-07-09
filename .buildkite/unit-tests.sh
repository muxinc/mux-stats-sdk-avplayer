PROJECT=$PWD/MUXSDKStats/MUXSDKStats.xcworkspace

xcodebuild clean test \
  -project $PROJECT \
  -scheme MUXSDKStats \
  -destination 'platform=iOS Simulator,name=iPhone 11,OS=14.1' \

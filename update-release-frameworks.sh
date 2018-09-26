# Delete the old stuff
rm -Rf Frameworks
# Make the target directories
mkdir -p Frameworks/iOS/fat
mkdir -p Frameworks/iOS/release
mkdir -p Frameworks/iOS/simulator
mkdir -p Frameworks/tvOS/fat
mkdir -p Frameworks/tvOS/release
mkdir -p Frameworks/tvOS/simulator

cd MUXSDKStats

# Build tvOS release SDK
xcodebuild -workspace 'MUXSDKStats.xcworkspace' -configuration Release archive -scheme 'MUXSDKStatsTv' SYMROOT=$PWD/tv
# Build tvOS simulator SDK
xcodebuild -workspace 'MUXSDKStats.xcworkspace' -configuration Release -scheme 'MUXSDKStatsTv' -destination 'platform=tvOS Simulator,name=Apple TV' SYMROOT=$PWD/tv

# Prepare the release .framework
cp -R -L tv/Release-appletvos/MUXSDKStatsTv.framework tv/MUXSDKStatsTv.framework
cp -R tv/Release-appletvos/MUXSDKStatsTv.framework.dSYM tv/MUXSDKStatsTv.framework.dSYM
TARGET_TV_BINARY=$PWD/tv/MUXSDKStatsTv.framework/MUXSDKStatsTv
rm $TARGET_TV_BINARY

# Make the tvOS fat binary
lipo -create tv/Release-appletvos/MUXSDKStatsTv.framework/MUXSDKStatsTv tv/Release-appletvsimulator/MUXSDKStatsTv.framework/MUXSDKStatsTv -output $TARGET_TV_BINARY


# Build iOS release SDK
xcodebuild -workspace 'MUXSDKStats.xcworkspace' -configuration Release archive -scheme 'MUXSDKStats' SYMROOT=$PWD/ios
# Build iOS simulator SDK
xcodebuild -workspace 'MUXSDKStats.xcworkspace' -configuration Release -scheme 'MUXSDKStats' -destination 'platform=iOS Simulator,name=iPhone 7' SYMROOT=$PWD/ios

# Prepare the release .framework
cp -R -L ios/Release-iphoneos/MUXSDKStats.framework ios/MUXSDKStats.framework
cp -R ios/Release-iphoneos/MUXSDKStats.framework.dSYM ios/MUXSDKStats.framework.dSYM
TARGET_IOS_BINARY=$PWD/ios/MUXSDKStats.framework/MUXSDKStats
rm $TARGET_IOS_BINARY

# Make the iOS fat binary
lipo -create ios/Release-iphoneos/MUXSDKStats.framework/MUXSDKStats ios/Release-iphonesimulator/MUXSDKStats.framework/MUXSDKStats -output $TARGET_IOS_BINARY

cd ..

# Copy over tvOS frameworks
cp -R MUXSDKStats/tv/Release-appletvsimulator/MUXSDKStatsTv.framework Frameworks/tvOS/simulator/MUXSDKStatsTv.framework
cp -R MUXSDKStats/tv/Release-appletvsimulator/MUXSDKStatsTv.framework.dSYM Frameworks/tvOS/simulator/MUXSDKStatsTv.framework.dSYM
cp -R -L MUXSDKStats/tv/Release-appletvos/MUXSDKStatsTv.framework Frameworks/tvOS/release/MUXSDKStatsTv.framework
cp -R MUXSDKStats/tv/Release-appletvos/MUXSDKStatsTv.framework.dSYM Frameworks/tvOS/release/MUXSDKStatsTv.framework.dSYM
cp -R MUXSDKStats/tv/MUXSDKStatsTv.framework Frameworks/tvOS/fat/MUXSDKStatsTv.framework
cp -R MUXSDKStats/tv/MUXSDKStatsTv.framework.dSYM Frameworks/tvOS/fat/MUXSDKStatsTv.framework.dSYM

# Copy over iOS frameworks
cp -R MUXSDKStats/ios/Release-iphonesimulator/MUXSDKStats.framework Frameworks/iOS/simulator/MUXSDKStats.framework
cp -R MUXSDKStats/ios/Release-iphonesimulator/MUXSDKStats.framework.dSYM Frameworks/iOS/simulator/MUXSDKStats.framework.dSYM
cp -R -L MUXSDKStats/ios/Release-iphoneos/MUXSDKStats.framework Frameworks/iOS/release/MUXSDKStats.framework
cp -R MUXSDKStats/ios/Release-iphoneos/MUXSDKStats.framework.dSYM Frameworks/iOS/release/MUXSDKStats.framework.dSYM
cp -R MUXSDKStats/ios/MUXSDKStats.framework Frameworks/iOS/fat/MUXSDKStats.framework
cp -R MUXSDKStats/ios/MUXSDKStats.framework.dSYM Frameworks/iOS/fat/MUXSDKStats.framework.dSYM


# Clean up
rm -Rf MUXSDKStats/tv
rm -Rf MUXSDKStats/ios

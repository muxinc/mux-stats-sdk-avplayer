BUILD_DIR=$PWD/MUXSDKStats/xc
PROJECT=$PWD/MUXSDKStats/MUXSDKStats.xcworkspace
TARGET_DIR=$PWD/XCFramework


# Delete the old stuff
rm -Rf $TARGET_DIR

# Make the build directory
mkdir -p $BUILD_DIR
# Make the target directory
mkdir -p $TARGET_DIR

################ Build MuxCore SDK

xcodebuild archive -scheme MUXSDKStatsTv -workspace $PROJECT -destination "generic/platform=tvOS" -archivePath "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
 xcodebuild archive -scheme MUXSDKStatsTv -workspace $PROJECT -destination "generic/platform=tvOS Simulator" -archivePath "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
 xcodebuild archive -scheme MUXSDKStats -workspace $PROJECT  -destination "generic/platform=iOS" -archivePath "$BUILD_DIR/MUXSDKStats.iOS.xcarchive" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
 xcodebuild archive -scheme MUXSDKStats -workspace $PROJECT  -destination "generic/platform=iOS Simulator" -archivePath "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
 
  xcodebuild archive -scheme MUXSDKStats -workspace $PROJECT  -destination "generic/platform=macOS,variant=Mac Catalyst" -archivePath "$BUILD_DIR/MUXSDKStats.macOS.xcarchive" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
  
 xcodebuild -create-xcframework -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStats.iOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStats.macOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -output "$TARGET_DIR/MUXSDKStats.xcframework"

rm -Rf $BUILD_DIR

BUILD_DIR=$PWD/MUXSDKStats/xc
PROJECT=$PWD/MUXSDKStats/MUXSDKStats.xcworkspace
TARGET_DIR=$PWD/XCFramework


# Delete the old stuff                                                                                                                                                                         
rm -Rf $TARGET_DIR

# Make the build directory                                                                                                                                                                     
mkdir -p $BUILD_DIR
# Make the target directory                                                                                                                                                                    
mkdir -p $TARGET_DIR

# Clean up on error
clean_up_error () {
    rm -Rf $BUILD_DIR
    exit 1
}

# Build and clean up on error
build () {
  scheme=$1
  destination="$2"
  path="$3"
  
  xcodebuild archive -scheme $scheme -workspace $PROJECT -destination "$destination" -archivePath "$path" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES CLANG_ENABLE_MODULES=NO MACH_O_TYPE=staticlib || clean_up_error
}

################ Build MuxSDKStats                                                                                                                                                             

build MUXSDKStatsTv "generic/platform=tvOS" "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive"
build MUXSDKStatsTv "generic/platform=tvOS Simulator" "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive"
build MUXSDKStats "generic/platform=iOS" "$BUILD_DIR/MUXSDKStats.iOS.xcarchive"
build MUXSDKStats "generic/platform=iOS Simulator" "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive"
build MUXSDKStats "generic/platform=macOS,variant=Mac Catalyst" "$BUILD_DIR/MUXSDKStats.macOS.xcarchive"

 xcodebuild -create-xcframework -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStatsTv.tvOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStats.iOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStats.iOS-simulator.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -framework "$BUILD_DIR/MUXSDKStats.macOS.xcarchive/Products/Library/Frameworks/MUXSDKStats.framework" \
                                -output "$TARGET_DIR/MUXSDKStats.xcframework" || clean_up_error

rm -Rf $BUILD_DIR

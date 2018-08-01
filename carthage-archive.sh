# Delete the old stuff
rm -Rf Carthage
# Make the target directories
mkdir -p Carthage/Build/iOS
mkdir -p Carthage/Build/tvOS

cp -r ./Frameworks/iOS/fat/*.* ./Carthage/Build/iOS
cp -r ./Frameworks/tvOS/fat/*.* ./Carthage/Build/tvOS

zip -r MUXSDKStats.framework.zip Carthage
rm -Rf Carthage

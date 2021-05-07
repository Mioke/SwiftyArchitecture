source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target "SAD" do
    # networking
	pod 'Alamofire'
    
    # rx
    pod 'RxSwift', '~> 5.0'
    pod 'RxDataSources'
    
    # persistence
    pod 'RxRealm'
    pod 'RealmSwift'
    
    # or sqlite
    pod 'FMDB'
    
    pod 'MIOSwiftyArchitecture', :path => './'

    
    # kits for demo
    pod 'YYModel'
    
#	pod 'ReactiveCocoa'
#	pod "AFNetworking"

#	pod "KMCache"
end

# pod 'FMDB/FTS'   # FMDB with FTS
# pod 'FMDB/standalone'   # FMDB with latest SQLite amalgamation source
# pod 'FMDB/standalone/FTS'   # FMDB with latest SQLite amalgamation source and FTS
# pod 'FMDB/SQLCipher'   # FMDB with SQLCipher


post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
    end
  end
end

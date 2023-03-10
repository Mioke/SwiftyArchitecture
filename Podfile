source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '15.0'
use_frameworks!
install! 'cocoapods', :preserve_pod_file_structure => true

target "SAD" do
  # networking
  pod 'Alamofire'
  
  # rx
  pod 'RxSwift', '~> 6.0'
  pod 'RxDataSources'
  
  # persistence
  pod 'RxRealm'
  pod 'RealmSwift'
  
  # or sqlite
  pod 'FMDB'
  
  pod 'MIOSwiftyArchitecture', :path => './', :testspecs => ['Tests']
  pod 'MIOSwiftyArchitecture/Testable', :path => './'
  
  

  # componentize
  pod 'Application', :path => './ComponentizeDemo/Application'
  pod 'ApplicationProtocol', :path => './ComponentizeDemo/Application'
  
  pod 'Auth', :path => './ComponentizeDemo/Auth'
  pod 'AuthProtocol', :path => './ComponentizeDemo/Auth'
  
#  pod 'Notification', :path => './ComponentizeDemo/Notification'
#  pod 'NotificationProtocol', :path => './ComponentizeDemo/Notification'

  pod 'Swinject'
  pod 'SwinjectAutoregistration'
  
  # other utils
  pod 'SnapKit'
  
  target 'SwiftArchitectureTests' do
    
  end
  
  target 'SwiftArchitectureUITests' do
    
  end
end

# pod 'FMDB/FTS'   # FMDB with FTS
# pod 'FMDB/standalone'   # FMDB with latest SQLite amalgamation source
# pod 'FMDB/standalone/FTS'   # FMDB with latest SQLite amalgamation source and FTS
# pod 'FMDB/SQLCipher'   # FMDB with SQLCipher


post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end

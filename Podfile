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

  # RxRealm not up-to-date, so we have to modify it ourselves.
  pod 'RxRealm', :git => 'https://github.com/Mioke/RxRealm.git', :branch => 'main'
  pod 'RealmSwift'

  pod 'MIOSwiftyArchitecture', :path => './', :testspecs => ['Tests']
  pod 'MIOSwiftyArchitecture/Testable', :path => './'

  pod 'SwiftyArchitectureMacrosPackage', :git => 'https://github.com/Mioke/SwiftyArchitectureMacros.git', :branch => 'dev'
#  pod 'SwiftyArchitectureMacros', :path => '/Users/kelanjiang/Documents/GitHub/SwiftyArchitectureMacros'

  # componentization
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
  pod 'FLEX'

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

  macro_product_folder = "${PODS_BUILD_DIR}/Products/SwiftyArchitectureMacros"

  installer_representation.pods_project.build_configurations.each do |config|
    config.build_settings['OTHER_SWIFT_FLAGS'] = "$(inherited) -load-plugin-executable #{macro_product_folder}/release/SwiftyArchitectureMacros#SwiftyArchitectureMacros"
  end

end

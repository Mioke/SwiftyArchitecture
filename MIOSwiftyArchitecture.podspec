#
# Be sure to run `pod lib lint UploadAcceleratorSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MIOSwiftyArchitecture'
  s.version          = '2.0.0'
  s.summary          = 'Breezy architecture in Swift for building iOS applications.'
  s.description      = <<-DESC
  * Breezy architecture in Swift for building iOS applications. It offers lots of functions which simple and easy to use for developer.
  DESC
  s.homepage         = 'https://github.com/Mioke/SwiftArchitectureWithPOP'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mioke Klein' => 'mioke0428@gmail.com' }
  s.source           = { :git => 'https://github.com/Mioke/SwiftArchitectureWithPOP.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.0'
  
  #  s.frameworks = 'UIKit', 'Foundation'
  # s.libraries = 'c++', 'sqlite3'
  
  #  s.source_files = 'SwiftyArchitecture/Base/**/*.swift'
  s.default_subspecs = 'Assistance', 'Networking', 'Persistance', 'RxExtension', 'AppDock', 'Componentize'
  
  s.subspec 'Assistance' do |ss|
    ss.frameworks = 'UIKit', 'Foundation'
    ss.source_files = 'SwiftyArchitecture/Base/Assistance/**/*.swift'
  end
  
  s.subspec 'Networking' do |ss|
    ss.frameworks = 'UIKit', 'Foundation'
    ss.source_files = 'SwiftyArchitecture/Base/Networking/**/*.swift'
    ss.dependency 'Alamofire', '~> 5.4'
    ss.dependency 'ObjectMapper', '~> 4.2'
    ss.dependency 'MIOSwiftyArchitecture/Assistance'
  end
  
  s.subspec 'Persistance' do |ss|
    ss.frameworks = 'UIKit', 'Foundation'
    ss.source_files = 'SwiftyArchitecture/Base/Persistance/**/*.swift'
    ss.dependency 'FMDB'
    ss.dependency 'MIOSwiftyArchitecture/Assistance'
  end
  
  s.subspec 'RxExtension' do |ss|
    ss.source_files = 'SwiftyArchitecture/Base/RxExtension/**/*.swift'
    ss.dependency 'MIOSwiftyArchitecture/Assistance'
    ss.dependency 'MIOSwiftyArchitecture/Networking'
    ss.dependency 'RxSwift', '~> 6.2'
  end
  
  s.subspec 'AppDock' do |ss|
    ss.source_files = 'SwiftyArchitecture/Base/AppDock/**/*.swift'
    ss.dependency 'MIOSwiftyArchitecture/Assistance'
    ss.dependency 'MIOSwiftyArchitecture/Networking'
    ss.dependency 'MIOSwiftyArchitecture/RxExtension'
    ss.dependency 'RxSwift', '~> 6.2'
    ss.dependency 'RxRealm', '~> 5.0'
    ss.dependency 'RealmSwift', '~> 10.20.0'
    ss.dependency "Realm", '~> 10.20.0'
  end
  
  s.subspec 'Componentize' do |ss|
    ss.source_files = 'SwiftyArchitecture/Base/Componentize/**/*.swift'
    ss.dependency 'MIOSwiftyArchitecture/Assistance'
    ss.dependency 'Swinject', '~> 2.8'
    ss.dependency 'RxSwift', '~> 6.2'
  end
  
  s.subspec 'Testable' do |ss|
    ss.source_files = 'SwiftyArchitecture/Base/Testable/**/*.swift'
    ss.dependency 'MIOSwiftyArchitecture/Assistance'
    ss.dependency 'MIOSwiftyArchitecture/Networking'
    ss.dependency 'MIOSwiftyArchitecture/RxExtension'
    ss.dependency 'MIOSwiftyArchitecture/AppDock'
    ss.dependency 'MIOSwiftyArchitecture/Componentize'
  end
  
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'SwiftyArchitecture/Base/Tests/**/*.swift'
#    test_spec.dependency 'OCMock' # This dependency will only be linked with your tests.
    test_spec.dependency 'MIOSwiftyArchitecture/Assistance'
    test_spec.dependency 'MIOSwiftyArchitecture/Networking'
    test_spec.dependency 'MIOSwiftyArchitecture/RxExtension'
    test_spec.dependency 'MIOSwiftyArchitecture/AppDock'
    test_spec.dependency 'MIOSwiftyArchitecture/Componentize'
    test_spec.dependency 'MIOSwiftyArchitecture/Testable'
    
    test_spec.dependency 'RxSwift', '~> 6.2'
  end
  
  # s.xcconfig = { "SWIFT_OBJC_BRIDGING_HEADER" => "SwiftyArchitecture/Resource/swiftArchitecture-Bridging-Header.h" }
  # s.module_map = 'SwiftyArchitecture/Resource/module.modulemap'
  
end

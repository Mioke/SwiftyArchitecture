#
# Be sure to run `pod lib lint UploadAcceleratorSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Application'
  s.version          = '0.0.1'
  s.summary          = 'Breezy architecture in Swift for building iOS applications.'
  s.description      = <<-DESC
  * Breezy architecture in Swift for building iOS applications. It offers lots of functions which simple and easy to use for developer.
  DESC
  s.homepage         = 'https://github.com/Mioke/SwiftArchitectureWithPOP'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mioke Klein' => 'mioke0428@gmail.com' }
  s.source           = { :git => 'https://github.com/Mioke/SwiftArchitectureWithPOP.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '11.0'
  s.swift_versions = '5.0'
  
  #  s.frameworks = 'UIKit', 'Foundation'
  # s.libraries = 'c++', 'sqlite3'
  
  s.source_files = 'Source/**/*.swift'

  s.dependency 'AuthProtocol'

  s.dependency 'ApplicationProtocol'
  s.dependency 'MIOSwiftyArchitecture'
  
  # s.xcconfig = { "SWIFT_OBJC_BRIDGING_HEADER" => "SwiftyArchitecture/Resource/swiftArchitecture-Bridging-Header.h" }
  # s.module_map = 'SwiftyArchitecture/Resource/module.modulemap'
  
end

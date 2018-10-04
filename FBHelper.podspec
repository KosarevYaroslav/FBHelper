#
#  Be sure to run `pod spec lint FBManager.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "FBHelper"
  s.version      = "0.1.0"
  s.summary      = "A short description of FBHelper."

  s.description  = <<-DESC
                    Helper for more easy access to FB features
                   DESC

  s.homepage     = "https://github.com/DrivePixels/FBHelper"

  s.license      = { :type => "MIT", :text => "FBHelper is licensed under the MIT License" }

  s.author       = { "sergey.zhdanov" => "sergey.zhdanov@drivepixels.ru" }

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/DrivePixels/FBHelper.git", :tag => "0.1.0" }

  s.source_files  = "FBHelper/FBHelper/FBHelper.{h,m}"
  s.requires_arc = true

  s.dependency "FBSDKCoreKit", '4.36.0'
  s.dependency "FBSDKLoginKit", '4.36.0'
  s.dependency "FBSDKShareKit", '4.36.0'
  s.dependency "AFNetworking"

end

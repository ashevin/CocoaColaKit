Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "CocoaColaKit"
s.summary = "CocoaColaKit is a miscellaneous collection of classes and utilities."
s.requires_arc = true

s.version = "0.1.0"

s.license = { :type => "MIT", :file => "LICENSE" }

s.author = { "Avi Shevin" => "avi.git@mail.ashevin.com" }

s.homepage = " https://github.com/ashevin/CocoaColaKit"

s.source = { :git => "https://github.com/ashevin/CocoaColaKit.git", :tag => "#{s.version}"}

s.framework = "UIKit"

s.source_files = "CocoaColaKit/**/*.{swift}"

end

Pod::Spec.new do |s|
  s.name         = "CNPPopupController"
  s.version      = "0.3.3"
  s.summary      = "A versatile popup for iOS"

  s.description  = <<-DESC
                   CNPPopupController is a simple and versatile class for presenting a custom popup in a variety of fashions.
                   It includes a many options for controlling how your popup appears and behaves.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/carsonperrotti/CNPPopupController"
  s.screenshots  = "https://raw.githubusercontent.com/carsonperrotti/CNPPopupController/master/CNPPopupControllerExample/CNPPopupController.gif"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author    = "Carson Perrotti"
  s.social_media_url   = "http://twitter.com/carsonp"
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/carsonperrotti/CNPPopupController.git", :tag => "0.3.3" }
  s.source_files  = "CNPPopupController", "CNPPopupController/*.{h,m}"
  s.framework  = "UIKit"
  s.requires_arc = true
end

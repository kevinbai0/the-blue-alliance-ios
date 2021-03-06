Pod::Spec.new do |s|
  s.name             = 'TBAKitTesting'
  s.version          = '1.0.0-LOCAL'
  s.summary          = 'Helper classes for testing/mocking TBAKit'

  s.homepage         = 'https://github.com/the-blue-alliance/the-blue-alliance-ios/tree/master/the-blue-alliance-ios/Frameworks/TBAKit/Testing'
  s.author           = 'ZachOrr'
  s.source           = { :git => 'https://thebluealliance.com/', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.source_files = 'Testing/**'
  s.framework = 'XCTest'

  s.dependency 'TBAKit'
end

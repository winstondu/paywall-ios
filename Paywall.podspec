Pod::Spec.new do |s|

	s.name         = "Paywall"
	s.version      = "0.0.1"
	s.summary      = "Superwall"
	s.description  = "Superwall"

	s.homepage     = "https://github.com/superwall-me/paywall-ios"
	s.license      = "MIT"
	s.source       = { :git => "https://github.com/superwall-me/paywall-ios", :tag => "#{s.version}" }

	s.author       = { "Pavel Tikhonenko" => "hi@tikhop.com" }

	s.swift_versions = ['5.3']
	s.ios.deployment_target = '12.0'
	s.requires_arc = true

  s.source_files  = "Sources/**/*.{swift}"
  s.resources  = "Sources/Paywall/*.xcassets"
  s.dependency 'TPInAppReceipt', '~> 3.0.0'


end

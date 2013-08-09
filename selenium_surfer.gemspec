# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'selenium_surfer/version'

Gem::Specification.new do |spec|
  spec.name          = "selenium_surfer"
  spec.version       = SeleniumSurfer::VERSION
  spec.authors       = ["Ignacio Baixas"]
  spec.email         = ["ignacio@platan.us"]
  spec.description   = %q{Selenium Surfer Robots!}
  spec.summary       = %q{Base infrastructure for webdriver robots with session managing and rich DSL}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'selenium-webdriver', "~> 2.33.0"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end

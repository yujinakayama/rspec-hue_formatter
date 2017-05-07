lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec/hue_formatter/version'

Gem::Specification.new do |spec|
  spec.name          = 'rspec-hue_formatter'
  spec.version       = Rspec::HueFormatter::Version.to_s
  spec.authors       = ['Yuji Nakayama']
  spec.email         = ['nkymyj@gmail.com']

  spec.summary       = 'Bring RSpec integration into your room with Philips Hue.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/yujinakayama/rspec-hue_formatter'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rspec-core', '~> 3.0'
  spec.add_runtime_dependency 'hue', '~> 0.1'

  spec.add_development_dependency 'bundler', '~> 1.3'
end

# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cinch/plugins/artifact/version'

Gem::Specification.new do |gem|
  gem.name          = "cinch-artifact"
  gem.version       = Cinch::Plugins::Artifact::VERSION
  gem.authors       = ["Brian Haberer"]
  gem.email         = ["bhaberer@gmail.com"]
  gem.description   = %q{Cinch PLugin for a simple game}
  gem.summary       = %q{Cinch Plugin for a game where a virtual item is passed back and forth}
  gem.homepage      = "https://github.com/bhaberer/cinch-artifact"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end

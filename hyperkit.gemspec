# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyperkit/version'

Gem::Specification.new do |spec|
  spec.name          = "hyperkit"
  spec.version       = Hyperkit::VERSION
  spec.authors       = ["Jeff Shantz"]
  spec.email         = ["hyperkit@jeffshantz.com"]

  spec.summary       = %q{Hyperkit is a flat API wrapper for LXD, the next-generation hypervisor}
  spec.homepage      = "http://jeffshantz.github.io/hyperkit"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  #if spec.respond_to?(:metadata)
  #  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  #else
  #  raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  #end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 4.2.6"
  spec.add_dependency "sawyer"
  spec.add_development_dependency "bundler", "~> 1.0"

end

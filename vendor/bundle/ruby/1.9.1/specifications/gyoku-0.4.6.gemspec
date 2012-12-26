# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "gyoku"
  s.version = "0.4.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Harrington"]
  s.date = "2012-06-28"
  s.description = "Gyoku converts Ruby Hashes to XML"
  s.email = "me@rubiii.com"
  s.homepage = "http://github.com/rubiii/gyoku"
  s.require_paths = ["lib"]
  s.rubyforge_project = "gyoku"
  s.rubygems_version = "1.8.24"
  s.summary = "Converts Ruby Hashes to XML"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<builder>, [">= 2.1.2"])
      s.add_development_dependency(%q<rake>, ["~> 0.9"])
      s.add_development_dependency(%q<rspec>, ["~> 2.10"])
    else
      s.add_dependency(%q<builder>, [">= 2.1.2"])
      s.add_dependency(%q<rake>, ["~> 0.9"])
      s.add_dependency(%q<rspec>, ["~> 2.10"])
    end
  else
    s.add_dependency(%q<builder>, [">= 2.1.2"])
    s.add_dependency(%q<rake>, ["~> 0.9"])
    s.add_dependency(%q<rspec>, ["~> 2.10"])
  end
end

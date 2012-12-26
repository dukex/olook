# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "simplecov-html"
  s.version = "0.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Christoph Olszowka"]
  s.date = "2011-09-12"
  s.description = "Default HTML formatter for SimpleCov code coverage tool for ruby 1.9+"
  s.email = ["christoph at olszowka de"]
  s.homepage = "https://github.com/colszowka/simplecov-html"
  s.require_paths = ["lib"]
  s.rubyforge_project = "simplecov-html"
  s.rubygems_version = "1.8.24"
  s.summary = "Default HTML formatter for SimpleCov code coverage tool for ruby 1.9+"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
  end
end

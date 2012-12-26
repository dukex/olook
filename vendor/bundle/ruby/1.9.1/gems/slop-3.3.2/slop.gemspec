Gem::Specification.new do |s|
  s.name        = 'slop'
  s.version     = '3.3.2'
  s.summary     = 'Option gathering made easy'
  s.description = 'A simple DSL for gathering options and parsing the command line'
  s.author      = 'Lee Jarvis'
  s.email       = 'lee@jarvis.co'
  s.homepage    = 'http://github.com/injekt/slop'
  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- test/*`.split("\n")

  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
end

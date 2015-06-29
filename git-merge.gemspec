$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'git-merge/version'

SEP = "\n"

Gem::Specification.new do |gem|
  gem.name        = 'git-merge'
  gem.version     = GitMerge::VERSION
  gem.license     = 'MIT'
  gem.authors     = ['Dmytro Milinevskyy']
  gem.email       = ['milinevskyy@gmail.com']
  gem.homepage    = 'http://github.com/niamster/git-merge'
  gem.summary     = 'A helper to merge GIT branches.'
  gem.description = 'Simple GIT helper to block undesired commits before merging branches.'

  gem.files         = `git ls-files`.split(SEP)
  gem.test_files    = `git ls-files -- {test,spec}/*`.split(SEP)
  gem.executables   = `git ls-files -- bin/*`.split(SEP).map { |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency 'commander',   '~> 4.3'
  gem.add_dependency 'rugged',      '~> 0.22'

  gem.add_development_dependency 'rake',    '~> 10.4'
  gem.add_development_dependency 'rspec',   '~> 3.0'
end

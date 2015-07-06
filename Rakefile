require 'bundler/gem_tasks'
require 'coveralls/rake/task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new
RSpec::Core::RakeTask.new(:rcov) do |task|
  task.rcov = true
end

Coveralls::RakeTask.new

unless ENV['CI']
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end

task :clean do
  rm_rf "coverage"
end

task :default do
  res = 0
  tasks = [:clean, :spec, 'coveralls:push']
  tasks << 'rubocop' unless ENV['CI']
  tasks.each do |tsk|
    if tsk == :spec
      sh 'rake spec' do |r|
        res = 1 unless r
      end
    else
      Rake::Task[tsk].invoke
    end
  end
  exit res
end

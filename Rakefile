# frozen_string_literal: true

require 'bundler'
require 'rake'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

# Import external rake tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task default: %i[rubocop rspec]

desc 'Run test suite'
task :rspec do
  RSpec::Core::RakeTask.new(:rspec)
end

desc 'Run linter & style checks'
task :rubocop do
  RuboCop::RakeTask.new
end

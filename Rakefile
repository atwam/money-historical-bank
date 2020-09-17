# frozen_string_literal: true

require 'rake/testtask'

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task default: %i[rubocop test]

Rake::TestTask.new do |t|
  t.pattern = 'test/*_test.rb'
end

# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'

def specs(dir)
  FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
end

desc 'Runs all the specs'
task :specs do
  sh "bundle exec bacon #{specs('**')}"
end

desc 'Lints all the files'
RuboCop::RakeTask.new(:rubocop)

task default: :specs

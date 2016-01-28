require 'optparse'
require 'fileutils'


module Remi
  module Cli
    extend self

    def execute
      parse
      initialize_project if @options[:init] == true
    end

    def parse(args = ARGV)
      options = {}

      opt_parser = OptionParser.new do |opts|
        opts.banner = <<-EOT.strip_heredoc
          Usage: Command line helpers for Remi.
        EOT

        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit
        end

        options[:init] = false
        opts.on('-i', '--init', 'Initialze a new Remi project') do
          options[:init] = true
        end
      end
      opt_parser.parse!(args)

      @options = options
    end

    def initialize_project
      template_dir = File.expand_path(File.join(File.dirname(__FILE__),'../../'))

      FileUtils.mkdir_p "features"
      FileUtils.cp(File.join(template_dir, 'features/sample_job.feature'), 'features')

      FileUtils.mkdir_p "features/support"
      FileUtils.cp(File.join(template_dir, 'features/support/env.rb'), 'features/support')
      FileUtils.cp(File.join(template_dir, 'features/support/env_app.rb'), 'features/support') unless File.exist?('features/support/env_app.rb')

      FileUtils.mkdir_p "features/step_definitions"
      FileUtils.cp(File.join(template_dir, 'features/step_definitions/remi_step.rb'), 'features/step_definitions')

      FileUtils.mkdir_p "jobs"
      FileUtils.cp(File.join(template_dir, 'jobs/all_jobs_shared.rb'), 'jobs') unless File.exist?('jobs/all_jobs_shared.rb')
      FileUtils.cp(File.join(template_dir, 'jobs/sample_job.rb'), 'jobs')
    end

  end
end

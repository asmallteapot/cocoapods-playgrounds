require 'xcodeproj'

module Pod
  class Command
    class Playgrounds < Command
      DEFAULT_PLATFORM_NAME = :ios

      self.summary = 'Generates a Swift Playground for any Pod.'

      self.description = <<-DESC
        Generates a Swift Playground for any Pod.
      DESC

      self.arguments = [CLAide::Argument.new('NAMES', true)]

      def self.options
        [
          ['--ipad', 'Create an iPad compatible Playground.'],
          ['--no-install', 'Skip running `pod install`'],
          ['--no-open', 'Do not open Xcode after generating the Playground.'],
          ['--platform', "Platform to generate for (default: #{DEFAULT_PLATFORM_NAME})"],
          ['--platform_version', 'Platform version to generate for ' \
            "(default: #{default_version_for_platform(DEFAULT_PLATFORM_NAME)})"]
        ]
      end

      def self.default_version_for_platform(platform)
        Xcodeproj::Constants.const_get("LAST_KNOWN_#{platform.upcase}_SDK")
      end

      def initialize(argv)
        arg = argv.shift_argument
        @names = arg.split(',') if arg
        @install = argv.flag?('install', true)
        @ipad = argv.flag?('ipad', false)
        @open = argv.flag?('open', true) && !@ipad
        @platform = argv.option('platform', DEFAULT_PLATFORM_NAME).to_sym
        @platform_version = argv.option('platform_version', Playgrounds.default_version_for_platform(@platform))
        super
      end

      def validate!
        super
        help! 'At least one Pod name is required.' unless @names
      end

      def run
        # TODO: Pass platform and deployment target from configuration
        generator = WorkspaceGenerator.new(@names, :cocoapods, @platform, @platform_version)
        name = generator.generate(@install, @open)

        if @ipad
          FileUtils.rm_rf(Dir.glob("#{name}Playground/*.xcodeproj"))
          FileUtils.rm_rf(Dir.glob("#{name}Playground/*.xcworkspace"))
          FileUtils.rm_f(Dir.glob("#{name}Playground/Podfile*"))

          playground_files = "#{name}Playground/#{name}.playground/Sources"
          FileUtils.mkdir_p(playground_files)
          pods = "#{name}Playground/Pods"

          Dir.glob("#{pods}/**/*.swift").each do |file|
            FileUtils.cp(file, playground_files)
          end
          FileUtils.rm_rf(pods)
        end
      end
    end
  end
end

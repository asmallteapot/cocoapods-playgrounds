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
          ['--no-migrate', 'Skip Swift migration for iPad Playgrounds.'],
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
        @migrate = argv.flag?('migrate', true)
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
            if @migrate
              migrate(file, "#{playground_files}/#{File.basename(file)}")
            else
              FileUtils.cp(file, playground_files)
            end
          end
          FileUtils.rm_rf(pods)

          File.open("#{name}Playground/#{name}.playground/Contents.swift", 'w') do |f|
            f.write("import PlaygroundSupport\n")
            f.write("PlaygroundPage.current.needsIndefiniteExecution = true\n\n")
          end
        end
      end

      private

      # Thanks to http://swift.ayaka.me/posts/2016/6/17/running-the-swift-30-migrator-on-a-standalone-swift-file
      def migrate(input, output)
        xcode_path = `xcode-select -p`.strip
        sdk_path = "#{xcode_path}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
        `xcrun swift-update -sdk '#{sdk_path}' -target arm64-apple-ios9 #{input} >#{output}`
        FileUtils.cp(input, output) if $?.exitstatus != 0
      end
    end
  end
end

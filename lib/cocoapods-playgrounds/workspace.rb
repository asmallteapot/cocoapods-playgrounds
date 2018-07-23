# frozen_string_literal: true

require 'cocoapods'
require 'cocoapods-playgrounds/generate'
require 'xcodeproj'

module Pod
  class WorkspaceGenerator
    SUPPORTED_TOOLS = %i[carthage cocoapods].freeze

    def initialize(names, tool = :cocoapods, platform = :ios, deployment_target = '9.0')
      @names = names
      @platform = platform
      @deployment_target = deployment_target

      raise "Unsupported tool #{tool}" unless SUPPORTED_TOOLS.include?(tool)
      @tool = tool
    end

    def generate(install = true)
      @cwd = Pathname.getwd
      `rm -fr '#{target_dir}'`
      FileUtils.mkdir_p(target_dir)

      Dir.chdir(target_dir) do
        setup_project(install)

        generator = Pod::PlaygroundGenerator.new(@platform, @names)
        path = generator.generate(names.first)
      end

      `open #{workspace_path}` if install
    end

    private

    def setup_project(install = true)
      case @tool
      when :carthage then
        generate_cartfile
        Pod::Executable.execute_command('carthage', ['update', '--platform', @platform.to_s])
        generate_project
        copy_carthage_frameworks
      when :cocoapods then
        generate_podfile
        generate_project
        Pod::Executable.execute_command('pod', ['install', '--no-repo-update']) if install
      end
    end

    def names
      @names.map do |name|
        if !(@cwd + name).exist? && name.include?('/')
          File.dirname(name)
        else
          File.basename(name, '.podspec')
        end
      end
    end

    def pods
      names.zip(@names).map do |name, path|
        abs_path = @cwd + path
        name = path unless abs_path.exist? # support subspecs
        requirement = "pod '#{name}'"
        requirement += ", :path => '#{abs_path.dirname}'" if abs_path.exist?
        requirement
      end.join("\n")
    end

    def target_dir
      Pathname.new(target_name)
    end

    def target_name
      "#{names.first}Playground"
    end

    def workspace_path
      extension = @tool == :cocoapods ? 'xcworkspace' : 'xcodeproj'
      target_dir + "#{names.first}.#{extension}"
    end

    def potential_cartfile
      potential_cartfile = @cwd + @names.first
      File.exist?(potential_cartfile) ? File.read(potential_cartfile) : nil
    end

    def generate_cartfile
      contents = if potential_cartfile
                   potential_cartfile
                 else
                   @names.map do |name|
                     "github \"#{name}\""
                   end.join("\n")
                 end
      File.open('Cartfile', 'w') { |f| f.write(contents) }
    end

    def carthage_platform_dir
      platform_dir = Dir.entries('Carthage/Build').find do |dir|
        dir.downcase.to_sym == @platform
      end
      raise "Could not find frameworks for platform #{@platform}" if platform_dir.nil?

      Pathname.new('Carthage/Build') + platform_dir
    end

    def derived_data_dir
      result = Pod::Executable.execute_command('xcodebuild',
                                               ['-configuration', 'Debug',
                                                '-sdk', 'iphonesimulator',
                                                '-showBuildSettings'])
      built_products_dir = result.lines.find do |line|
        line[/ BUILT_PRODUCTS_DIR =/]
      end.split('=').last.strip
      Pathname.new(built_products_dir)
    end

    def copy_carthage_frameworks
      Dir.entries(carthage_platform_dir).each do |entry|
        next unless entry.end_with?('.framework')
        FileUtils.mkdir_p(derived_data_dir)
        FileUtils.cp_r(carthage_platform_dir + entry, derived_data_dir)
      end
    end

    def podfile
      <<~PODFILE
        platform :#{@platform}, '#{@deployment_target}'
        use_frameworks!
        inhibit_all_warnings!

        target '#{target_name}' do
          #{pods}
        end

        post_install do |installer|
          installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
              config.build_settings['CONFIGURATION_BUILD_DIR'] = '$PODS_CONFIGURATION_BUILD_DIR'
            end
          end
        end
      PODFILE
    end

    def generate_podfile
      File.open('Podfile', 'w') { |f| f.write(podfile) }
    end

    def generate_project
      project_path = "#{names.first}.xcodeproj"
      project = Xcodeproj::Project.new(project_path)

      target = project.new_target(:application,
                                  target_name,
                                  @platform,
                                  @deployment_target)
      target.build_configurations.each do |config|
        config.build_settings['ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME'] = 'LaunchImage'
        config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = ''
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
        config.build_settings['DEFINES_MODULE'] = 'NO'
        config.build_settings['EMBEDDED_CONTENT_CONTAINS_SWIFT'] = 'NO'
      end

      # TODO: Should be at the root of the project
      project.new_file("#{names.first}.playground")
      project.save
    end
  end
end

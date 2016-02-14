require 'cocoapods'
require 'cocoapods-playgrounds/generate'
require 'xcodeproj'

module Pod
  class WorkspaceGenerator
    SUPPORTED_TOOLS = [:carthage, :cocoapods].freeze

    def initialize(names, tool = :cocoapods, platform = :ios, deployment_target = '9.0')
      @names = names
      @platform = platform
      @deployment_target = deployment_target

      fail "Unsupported tool #{tool}" unless SUPPORTED_TOOLS.include?(tool)
      @tool = tool
    end

    def generate
      @cwd = Pathname.getwd
      `rm -fr #{target_dir}`
      FileUtils.mkdir_p(target_dir)

      Dir.chdir(target_dir) do
        setup_project

        generator = Pod::PlaygroundGenerator.new(@platform)
        path = generator.generate(names.first)
        generate_swift_code(path)
      end

      `open #{workspace_path}`
    end

    private

    def setup_project
      case @tool
      when :carthage then
        generate_cartfile
        Pod::Executable.execute_command('carthage', ['update', '--platform', @platform.to_s])
        generate_project
        copy_carthage_frameworks
      when :cocoapods then
        generate_podfile
        generate_project
        Pod::Executable.execute_command('pod', ['install', '--no-repo-update'])
      end
    end

    def names
      @names.map do |name|
        File.basename(name, '.podspec')
      end
    end

    def pods
      names.zip(@names).map do |name, path|
        path = @cwd + path
        requirement = "pod '#{name}'"
        requirement += ", :path => '#{path.dirname}'" if path.exist?
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

    def generate_cartfile
      contents = @names.map do |name|
        "github \"#{name}\""
      end.join("\n")
      File.open('Cartfile', 'w') { |f| f.write(contents) }
    end

    def carthage_platform_dir
      platform_dir = Dir.entries('Carthage/Build').find do |dir|
        dir.downcase.to_sym == @platform
      end
      fail "Could not find frameworks for platform #{@platform}" if platform_dir.nil?

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
        FileUtils.cp_r(carthage_platform_dir + entry, derived_data_dir)
      end
    end

    def generate_podfile
      contents = "use_frameworks!\n\n"
      contents << "target '#{target_name}' do\n"
      contents << "#{pods}\n"
      contents << "end\n"
      File.open('Podfile', 'w') { |f| f.write(contents) }
    end

    def generate_project
      project_path = "#{names.first}.xcodeproj"
      project = Xcodeproj::Project.new(project_path)

      target = project.new_target(:framework,
                                  target_name,
                                  @platform,
                                  @deployment_target)
      target.build_configurations.each do |config|
        config.build_settings['DEFINES_MODULE'] = 'NO'
      end

      # TODO: Should be at the root of the project
      project.new_file("#{names.first}.playground")
      project.save
    end

    def generate_swift_code(path)
      File.open(path + 'Contents.swift', 'w') do |f|
        f.write("//: Please build the scheme '#{target_name}' first\n")
        f.write("import XCPlayground\n")
        f.write("XCPlaygroundPage.currentPage.needsIndefiniteExecution = true\n\n")
        names.each do |name|
          f.write("import #{name}\n")
        end
        f.write("\n")
      end
    end
  end
end

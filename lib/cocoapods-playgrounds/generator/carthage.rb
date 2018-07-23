# frozen_string_literal: true

require 'cocoapods'
require 'cocoapods-playgrounds/playground'

module Pod
  class CarthageGenerator < Pod::WorkspaceGenerator
    def setup_project(install = true)
      generate_cartfile
      Pod::Executable.execute_command('carthage', ['update', '--platform', @platform.to_s])
      generate_project
      copy_carthage_frameworks
    end

    def workspace_extension
      'xcodeproj'
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

    def copy_carthage_frameworks
      Dir.entries(carthage_platform_dir).each do |entry|
        next unless entry.end_with?('.framework')
        FileUtils.mkdir_p(derived_data_dir)
        FileUtils.cp_r(carthage_platform_dir + entry, derived_data_dir)
      end
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
  end
end

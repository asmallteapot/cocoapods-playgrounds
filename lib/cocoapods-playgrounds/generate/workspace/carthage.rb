# frozen_string_literal: true

require 'cocoapods-playgrounds/generate/workspace'

module Pod
  # Playground workspace generator for Carthage
  class CarthageGenerator < Pod::WorkspaceGenerator
    def generate_spec_file
      File.open('Cartfile', 'w') { |f| f.write(cartfile_contents) }
    end

    def perform_update_by_default?
      true
    end

    def perform_update
      Pod::Executable.execute_command('carthage', ['update', '--platform', @platform.to_s])
    end

    def perform_install
      Dir.entries(carthage_platform_dir).each do |entry|
        next unless entry.end_with?('.framework')
        FileUtils.mkdir_p(derived_data_dir)
        FileUtils.cp_r(carthage_platform_dir + entry, derived_data_dir)
      end
    end

    def perform_open_workspace
      `open #{workspace_path}`
    end

    private

    def workspace_path
      @app_target_dir + "#{@workspace_name}.xcodeproj"
    end

    def potential_cartfile
      potential_cartfile = @cwd + @workspace_name
      File.exist?(potential_cartfile) ? File.read(potential_cartfile) : nil
    end

    def cartfile_contents
      potential_cartfile || @spec_names.map do |name|
        "github \"#{name}\""
      end.join("\n")
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

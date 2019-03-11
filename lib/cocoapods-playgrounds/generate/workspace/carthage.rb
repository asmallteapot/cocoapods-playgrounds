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
      `open #{@output_path_project}`
    end

    private

    def input_cartfile_path
      @input_dir + @base_name
    end

    def input_cartfile_contents
      File.file?(input_cartfile_path) ? File.read(input_cartfile_path) : nil
    end

    def requirement_for_dependency(name, source: 'github')
      <<~SPEC
        #{source} "#{name}"
      SPEC
    end

    def generated_cartfile_contents
      @dependencies.map do |name|
        requirement_for_dependency name
      end.join("\n")
    end

    def cartfile_contents
      input_cartfile_contents || generated_cartfile_contents
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

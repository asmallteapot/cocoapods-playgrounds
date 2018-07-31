# frozen_string_literal: true

require 'cocoapods'
require 'cocoapods-playgrounds/generate/playground'
require 'xcodeproj'

module Pod
  # Base class for generating a workspace that contains a playground and its dependencies
  class WorkspaceGenerator
    def initialize(name: nil, dependencies: [], platform: :ios, deployment_target: '9.0')
      @base_name = name || 'Empty'
      @dependencies = dependencies
      @platform = platform
      @deployment_target = deployment_target

      @app_target_name = "#{@base_name}Playground"

      @input_dir = Pathname.getwd
      @output_dir = @input_dir + Pathname.new(@base_name)
      @output_path_workspace = @output_dir + "#{@base_name}.xcworkspace"
      @output_path_project = @output_dir + "#{@base_name}.xcodeproj"
      @output_path_playground = @output_dir + "#{@base_name}.playground"
    end

    def generate(install: true, open_workspace: install)
      FileUtils.rm_rf @output_dir
      FileUtils.mkdir_p @output_dir
      Dir.chdir(@output_dir) do
        generate_spec_file
        perform_update if perform_update_by_default?
        generate_project
        perform_install if install
        generate_playground
        perform_open_workspace if open_workspace
      end
    end

    private

    def generate_spec_file
      raise NotImplementedError, "#{self.class.name}##{method} must be overridden."
    end

    def perform_update
      raise NotImplementedError, "#{self.class.name}##{method} must be overridden."
    end

    def perform_install
      raise NotImplementedError, "#{self.class.name}##{method} must be overridden."
    end

    def perform_update_by_default?
      raise NotImplementedError, "#{self.class.name}##{method} must be overridden."
    end

    def perform_open_workspace
      raise NotImplementedError, "#{self.class.name}##{method} must be overridden."
    end

    def generate_project
      project = Xcodeproj::Project.new(@output_path_project)

      target = project.new_target(:application,
                                  @app_target_name,
                                  @platform,
                                  @deployment_target)
      target.build_configurations.each do |config|
        update_build_settings(config)
      end

      # TODO: Should be at the root of the project
      project.new_file(@output_path_playground)
      project.save
    end

    def update_build_settings(config)
      config.build_settings['ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME'] = 'LaunchImage'
      config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = ''
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['DEFINES_MODULE'] = 'NO'
      config.build_settings['EMBEDDED_CONTENT_CONTAINS_SWIFT'] = 'NO'
      # TODO: define swift version correctly
      config.build_settings['SWIFT_VERSION'] = '4.0'
    end

    def generate_playground
      generator = Pod::PlaygroundGenerator.new(@platform, @dependencies)
      generator.generate(@base_name)
    end
  end
end

# frozen_string_literal: true

require 'cocoapods'
require 'cocoapods-playgrounds/generate/playground'
require 'xcodeproj'

module Pod
  # Base class for generating a workspace that contains a playground and its dependencies
  class WorkspaceGenerator
    def initialize(workspace_name, spec_names, platform = :ios, deployment_target = '9.0')
      @workspace_name = workspace_name
      @spec_names = spec_names
      @platform = platform
      @deployment_target = deployment_target
    end

    def generate(install: true, open_workspace: install)
      generate_app_target(name: "#{@workspace_name}Playground") do
        generate_spec_file
        perform_update if perform_update_by_default?
        generate_project
        perform_install if install
        generate_playground
      end

      perform_open_workspace if open_workspace
    end

    private

    def generate_app_target(name:, clean: true)
      @app_target_name = name
      @app_target_dir = Pathname.new(@app_target_name)

      `rm -fr '#{@app_target_dir}'` if clean
      FileUtils.mkdir_p(@app_target_dir)

      @cwd = Pathname.getwd
      Dir.chdir(@app_target_dir) do
        yield
      end
    end

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
      project_path = "#{@workspace_name}.xcodeproj"
      project = Xcodeproj::Project.new(project_path)

      target = project.new_target(:application,
                                  @app_target_name,
                                  @platform,
                                  @deployment_target)
      target.build_configurations.each do |config|
        update_build_settings(config)
      end

      # TODO: Should be at the root of the project
      project.new_file("#{@workspace_name}.playground")
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
      generator = Pod::PlaygroundGenerator.new(@platform, @spec_names)
      generator.generate(@workspace_name)
    end
  end
end

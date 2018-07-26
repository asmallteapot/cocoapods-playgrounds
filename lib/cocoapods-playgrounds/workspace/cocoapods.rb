# frozen_string_literal: true

require 'cocoapods-playgrounds/workspace'

module Pod
  # Playground workspace generator for CocoaPods
  class CocoaPodsGenerator < Pod::WorkspaceGenerator
    def generate_spec_file
      File.open('Podfile', 'w') { |f| f.write(podfile_contents) }
    end

    def perform_update_by_default?
      false
    end

    def perform_update
      Pod::Executable.execute_command('pod', %w[repo update])
    end

    def perform_install
      Pod::Executable.execute_command('pod', ['install', '--no-repo-update'])
    end

    def perform_open_workspace
      `open #{workspace_path}`
    end

    private

    def workspace_path
      @app_target_dir + "#{@workspace_name}.xcworkspace"
    end

    def specs
      @spec_names.map do |name|
        if !(@cwd + name).exist? && name.include?('/')
          File.dirname(name)
        else
          File.basename(name, '.podspec')
        end
      end
    end

    def pods
      specs.zip(@spec_names).map do |name, path|
        abs_path = @cwd + path
        name = path unless abs_path.exist? # support subspecs
        requirement = "pod '#{name}'"
        requirement += ", :path => '#{abs_path.dirname}'" if abs_path.exist?
        requirement
      end.join("\n")
    end

    def podfile_contents
      <<~PODFILE
        platform :#{@platform}, '#{@deployment_target}'
        use_frameworks!
        inhibit_all_warnings!

        target '#{@app_target_name}' do
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
  end
end

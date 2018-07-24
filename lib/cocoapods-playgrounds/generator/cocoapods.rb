# frozen_string_literal: true

require 'cocoapods'
require 'cocoapods-playgrounds/playground'

module Pod
  class CocoaPodsGenerator < Pod::WorkspaceGenerator
    def setup_project(install = true)
      generate_podfile
      generate_project
      Pod::Executable.execute_command('pod', ['install', '--no-repo-update']) if install
    end

    def workspace_extension
      'xcworkspace'
    end

    def pods
      names.zip(@dependency_names).map do |name, path|
        abs_path = @cwd + path
        name = path unless abs_path.exist? # support subspecs
        requirement = "pod '#{name}'"
        requirement += ", :path => '#{abs_path.dirname}'" if abs_path.exist?
        requirement
      end.join("\n")
    end

    def podfile
      <<~PODFILE
        platform :#{@platform}, '#{@deployment_target}'
        use_frameworks!
        inhibit_all_warnings!

        target '#{@target_name}' do
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
  end
end

# frozen_string_literal: true

require 'cocoapods-playgrounds/generate/workspace'

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
      `open #{@output_path_workspace}`
    end

    private

    def requirement_for_spec(spec_name, dependency)
      local_path = @input_dir + dependency
      if local_path.exist?
        <<~SPEC
          pod '#{spec_name}', path: '#{local_path.dirname}'
        SPEC
      else
        <<~SPEC
          pod '#{dependency}'
        SPEC
      end
    end

    def spec_names
      @dependencies.map do |name|
        abs_path = @input_dir + name
        if !abs_path.exist? && name.include?('/')
          File.dirname(name)
        else
          File.basename(name, '.podspec')
        end
      end
    end

    def pods
      spec_names.zip(@dependencies).map do |spec_name, dependency|
        requirement_for_spec spec_name, dependency
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

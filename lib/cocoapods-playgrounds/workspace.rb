module Pod
  class WorkspaceGenerator
    def initialize(names, platform = :ios, deployment_target = '9.0')
      @names = names
      @platform = platform
      @deployment_target = deployment_target
    end

    def generate
      @cwd = Pathname.getwd
      generate_project

      Dir.chdir(target_dir) do
        generate_podfile
        Pod::Executable.execute_command('pod', ['install', '--no-repo-update'])

        generator = Pod::PlaygroundGenerator.new(@platform)
        path = generator.generate(names.first)
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

      `open #{workspace_path}`
    end

    private

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
      target_dir + "#{names.first}.xcworkspace"
    end

    def generate_podfile
      contents = "use_frameworks!\n\n"
      contents << "target '#{target_name}' do\n"
      contents << "#{pods}\n"
      contents << "end\n"
      File.open('Podfile', 'w') { |f| f.write(contents) }
    end

    def generate_project
      `rm -fr #{target_dir}`
      FileUtils.mkdir_p(target_dir)

      project_path = "#{target_dir}/#{names.first}.xcodeproj"
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
  end
end

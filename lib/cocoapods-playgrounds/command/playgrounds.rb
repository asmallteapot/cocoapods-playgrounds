module Pod
  class Command
    class Playgrounds < Command
      self.summary = 'Generates a Swift Playground for any Pod.'

      self.description = <<-DESC
        Generates a Swift Playground for any Pod.
      DESC

      self.arguments = [CLAide::Argument.new('NAME', true)]

      def initialize(argv)
        @name = argv.shift_argument
        @platform = :ios # TODO: Should be configurable
        @deployment_target = '9.0' # TODO: Should be configurable
        super
      end

      def validate!
        super
        help! 'A Pod name is required.' unless @name
      end

      def run
        generate_project

        Dir.chdir(target_dir) do
          generate_podfile
          Pod::Executable.execute_command('pod', ['install', '--no-repo-update'])
          generator = Pod::PlaygroundGenerator.new(@platform)
          path = generator.generate(@name)
          File.open(path + 'Contents.swift', 'w') do |f|
            f.write("//: Please build the scheme '#{target_name}' first\n")
            f.write("import XCPlayground\n")
            f.write("XCPlaygroundPage.currentPage.needsIndefiniteExecution = true\n\n")
            f.write("import #{@name}\n\n")
          end
        end

        `open #{workspace_path}`
      end

      private

      def target_dir
        Pathname.new(target_name)
      end

      def target_name
        "#{@name}Playground"
      end

      def workspace_path
        target_dir + "#{@name}.xcworkspace"
      end

      def generate_podfile
        contents = "use_frameworks!\n\n"
        contents << "target '#{target_name}' do\n"
        contents << "pod '#{@name}'\n"
        contents << "end\n"
        File.open('Podfile', 'w') { |f| f.write(contents) }
      end

      def generate_project
        `rm -fr #{target_dir}`
        FileUtils.mkdir_p(target_dir)

        project_path = "#{target_dir}/#{@name}.xcodeproj"
        project = Xcodeproj::Project.new(project_path)

        target = project.new_target(:framework,
                                    target_name,
                                    @platform,
                                    @deployment_target)
        target.build_configurations.each do |config|
          config.build_settings['DEFINES_MODULE'] = 'NO'
        end

        # TODO: Should be at the root of the project
        project.new_file("#{@name}.playground")
        project.save
      end
    end
  end
end

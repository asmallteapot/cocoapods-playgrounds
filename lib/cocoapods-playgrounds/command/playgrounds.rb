module Pod
  class Command
    class Playgrounds < Command
      self.summary = 'Generates a Swift Playground for any Pod.'

      self.description = <<-DESC
        Generates a Swift Playground for any Pod.
      DESC

      self.arguments = [CLAide::Argument.new('NAMES', true)]

      def self.options
        [
          ['--no-install', 'Skip running `pod install`']
        ]
      end

      def initialize(argv)
        arg = argv.shift_argument
        @names = arg.split(',') if arg
        @install = argv.flag?('install', true)
        super
      end

      def validate!
        super
        help! 'At least one Pod name is required.' unless @names
      end

      def run
        # TODO: Pass platform and deployment target from configuration
        generator = WorkspaceGenerator.new(@names)
        generator.generate(@install)
      end
    end
  end
end

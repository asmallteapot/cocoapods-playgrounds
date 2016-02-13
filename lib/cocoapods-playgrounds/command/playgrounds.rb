module Pod
  class Command
    class Playgrounds < Command
      self.summary = 'Generates a Swift Playground for any Pod.'

      self.description = <<-DESC
        Generates a Swift Playground for any Pod.
      DESC

      self.arguments = [CLAide::Argument.new('NAMES', true)]

      def initialize(argv)
        arg = argv.shift_argument
        @names = arg.split(',') if arg
        super
      end

      def validate!
        super
        help! 'At least one Pod name is required.' unless @names
      end

      def run
        # TODO: Pass platform and deployment target from configuration
        generator = WorkspaceGenerator.new(@names)
        generator.generate
      end
    end
  end
end

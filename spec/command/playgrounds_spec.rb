require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Playgrounds do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w( playgrounds )).should.be.instance_of Command::Playgrounds
      end
    end
  end
end

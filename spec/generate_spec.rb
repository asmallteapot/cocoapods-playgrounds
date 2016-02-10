require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe PlaygroundGenerator do
    it 'can find the template directory' do
      template_dir = PlaygroundGenerator.template_dir

      template_dir.extname.should == '.xctemplate'
      template_dir.exist?.should == true
    end

    it 'can list available platforms for Playgrounds' do
      platforms = PlaygroundGenerator.platforms

      platforms.should == [:ios, :osx, :tvos]
    end

    it 'returns nil if template for platform cannot be found' do
      platform = PlaygroundGenerator.dir_for_platform(:watchos)

      platform.should.nil?
    end

    it 'can find the template for OS X' do
      platform = PlaygroundGenerator.dir_for_platform(:osx)

      platform.to_s.end_with?('OS X').should == true
    end

    it 'can find the template for iOS' do
      platform = PlaygroundGenerator.dir_for_platform(:ios)

      platform.to_s.end_with?('iOS').should == true
    end
  end
end

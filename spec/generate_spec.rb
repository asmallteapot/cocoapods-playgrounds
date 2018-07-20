require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe PlaygroundGenerator do
    it 'imports the correct base framework for all platforms' do
      [:ios, :macos, 'tvos'].map { |platform|
        PlaygroundGenerator.new(platform).base_framework
      }.should == ['UIKit', 'Cocoa', 'UIKit']
    end
  end
end

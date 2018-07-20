# frozen_string_literal: true

require File.expand_path('spec_helper', __dir__)

module Pod
  describe PlaygroundGenerator do
    it 'imports the correct base framework for all platforms' do
      [:ios, :macos, 'tvos'].map do |platform|
        PlaygroundGenerator.new(platform).base_framework
      end.should == %w[UIKit Cocoa UIKit]
    end
  end
end

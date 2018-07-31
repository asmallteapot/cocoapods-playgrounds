# frozen_string_literal: true

require 'fileutils'
require 'pathname'

module Pod
  # Generates a Swift playground
  class PlaygroundGenerator
    def initialize(platform, import_names = [])
      @platform = platform
      @import_names = import_names
    end

    def generate(name)
      playground_path = Pathname.new(name + '.playground')
      FileUtils.mkdir(playground_path)

      contents_swift_path = playground_path + 'Contents.swift'
      contents_swift_path.write(contents_swift)

      contents_xcplayground_path = playground_path + 'Contents.xcplayground'
      contents_xcplayground_path.write(contents_xcplayground)

      playground_path
    end

    def base_framework
      if @platform == :macos
        'Cocoa'
      else
        'UIKit'
      end
    end

    def contents_swift_imports
      all_import_names = [base_framework, 'PlaygroundSupport'] # + @import_names
      all_import_names.map { |name| "import #{name}" }.join("\n")
    end

    def contents_swift
      <<~CONTENTS_SWIFT
        //: Playground - noun: a place where people can play
        //: Press Cmd-B to build your CocoaPods.

        #{contents_swift_imports}

        // Uncomment this to let your code keep running in the background.
        // PlaygroundPage.current.needsIndefiniteExecution = true

        var str = "Hello, playground"
      CONTENTS_SWIFT
    end

    def contents_xcplayground
      <<~CONTENTS_XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <playground version='5.0' target-platform='#{@platform}'>
            <timeline fileName='timeline.xctimeline'/>
        </playground>
      CONTENTS_XML
    end
  end
end

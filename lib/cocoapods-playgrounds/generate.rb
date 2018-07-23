# frozen_string_literal: true

require 'fileutils'
require 'pathname'

module Pod
  class PlaygroundGenerator
    def initialize(platform)
      @platform = platform
    end

    def generate(name)
      path = Pathname.new(name + '.playground')
      FileUtils.mkdir(path)

      contents_swift_path = path + 'Contents.swift'
      contents_swift_path.write(contents_swift)

      contents_xcplayground_path = path + 'Contents.xcplayground'
      contents_xcplayground_path.write(contents_xcplayground)
    end

    def base_framework
      if @platform == :macos
        'Cocoa'
      else
        'UIKit'
      end
    end

    def contents_swift
      <<~CONTENTS_SWIFT
        //: Playground - noun: a place where people can play

        import #{base_framework}

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

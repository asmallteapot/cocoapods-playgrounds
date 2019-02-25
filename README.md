# CocoaPods Playgrounds

[![RubyGems](https://img.shields.io/gem/v/cocoapods-playgrounds.svg?style=flat)](https://rubygems.org/gems/cocoapods-playgrounds)
[![MIT license](https://img.shields.io/github/license/asmallteapot/cocoapods-playgrounds.svg)](https://github.com/asmallteapot/cocoapods-playgrounds/blob/master/LICENSE.txt)
[![Build Status](https://img.shields.io/travis/asmallteapot/cocoapods-playgrounds/master.svg?style=flat)](https://travis-ci.org/asmallteapot/cocoapods-playgrounds)

Generate a Swift Playground for any CocoaPod or Carthage module.

![](README_images/alamofire.png)

## Installation

    $ gem install cocoapods-playgrounds

## Usage

### CocoaPods

To generate a Playground for a specific Pod:

    $ pod playgrounds Alamofire

To generate a Playground for a local development Pod:

    $ pod playgrounds ../../../Sources/Alamofire/Alamofire.podspec

To generate a Playground with multiple Pods:

    $ pod playgrounds RxSwift,RxCocoa

### Carthage

To generate a Playground for a Carthage-enabled library:

    $ carthage-play Alamofire/Alamofire

Note: This currently assumes that libraries are hosted on GitHub.

### CLI

To generate an empty Playground from the commandline:

    $ playground --platform=ios YOLO
    $ open YOLO.playground

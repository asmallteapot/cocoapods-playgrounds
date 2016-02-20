# This Could Be Us But You Playing

[![Build Status](https://img.shields.io/travis/neonichu/ThisCouldBeUsButYouPlaying/master.svg?style=flat)](https://travis-ci.org/neonichu/ThisCouldBeUsButYouPlaying)

![](README_images/alamofire.png)

Generates a Swift Playground for any Pod.

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

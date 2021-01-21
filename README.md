# ExCoreData

[![CI Status](https://img.shields.io/travis/Jirokichi/ExCoreData.svg?style=flat)](https://travis-ci.org/Jirokichi/ExCoreData)
[![Version](https://img.shields.io/cocoapods/v/ExCoreData.svg?style=flat)](https://cocoapods.org/pods/ExCoreData)
[![License](https://img.shields.io/cocoapods/l/ExCoreData.svg?style=flat)](https://cocoapods.org/pods/ExCoreData)
[![Platform](https://img.shields.io/cocoapods/p/ExCoreData.svg?style=flat)](https://cocoapods.org/pods/ExCoreData)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS Deployment Target 11.0 or later

## Installation

ExCoreData is not available through [CocoaPods](https://cocoapods.org) yet. To install
it, simply add the following line to your Podfile:

```ruby
pod 'ExCoreData', :git => 'https://github.com/chorokichi/ExCoreData.git'
```

## 使い方

- ExCoreData を継承し、data 変数を override したクラス(ここでは仮に ChildCoreData とする)を作成する
- `ChildCoreData.initInstance`を呼び出せば、CoreData の初期化が実行され、引数コールバック変数でその結果を受け取れる

## Author

Jirokichi, kdy.developer@gmail.com

## License

ExCoreData is available under the MIT license. See the LICENSE file for more info.

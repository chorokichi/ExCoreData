# ExCoreData

[![CI Status](https://img.shields.io/travis/Jirokichi/ExCoreData.svg?style=flat)](https://travis-ci.org/Jirokichi/ExCoreData)
[![Version](https://img.shields.io/cocoapods/v/ExCoreData.svg?style=flat)](https://cocoapods.org/pods/ExCoreData)
[![License](https://img.shields.io/cocoapods/l/ExCoreData.svg?style=flat)](https://cocoapods.org/pods/ExCoreData)
[![Platform](https://img.shields.io/cocoapods/p/ExCoreData.svg?style=flat)](https://cocoapods.org/pods/ExCoreData)

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [ExCoreData](#excoredata)
  - [Example](#example)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [このライブラリの狙い](#このライブラリの狙い)
    - [① `NSManagedObjectContext` の初期化・生成方法](#1-nsmanagedobjectcontext-の初期化生成方法)
    - [② 複数の DB ファイルを利用する方法](#2-複数の-db-ファイルを利用する方法)
    - [③ NSManagedObject の簡単な利用手段](#3-nsmanagedobject-の簡単な利用手段)
      - [ExRecords を継承したクラスの生成方法](#exrecords-を継承したクラスの生成方法)
      - [ExRecords を継承したクラスでできること](#exrecords-を継承したクラスでできること)
  - [注意事項](#注意事項)
  - [Author](#author)
  - [License](#license)

<!-- /code_chunk_output -->

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

## このライブラリの狙い

① `NSManagedObjectContext` をひとつの静的メソッドを呼び出すだけで簡単に初期化・生成できる方法を提供すること
② 複数の DB ファイルをを対応するクラスを生成するだけで扱えるようにすること
③ NSManagedObject の作成/取得/削除/更新を簡単に実行できる手段を提供すること

それぞれ実現するための方法を次に説明する。

### ① `NSManagedObjectContext` の初期化・生成方法

ExCoreData がこの機能を提供する。
次の手順で NSManagedObjectContext を管理できる。

1. ExCoreData を継承したクラスを作成し、data 変数を override して ExCoreData.RequiredData を返すようにする

   ```swift
   // 前提：Model.xcdatamodeldを作成してProjectに追加しておくこと
   import ExCoreData
   ...
   // 例
   class ExampleCoreData: ExCoreData{
       override var data: ExCoreData.RequiredData {
           let data = ExCoreData.RequiredData(
               "Model", // xcdatamodeldファイルの拡張子を除いた名前
               "jp.example.excoredata", // packageName
               "Example") // ストア名。任意の名前。この名前の後ろに.sqliteがついたファイルが作成されることになる。
           return data
       }
   }
   ```

2. NSManagedObjectContext を初期化したい箇所で、{ExCoreData を継承したクラス}#initInstance を呼び出す

   ```swift
   import ExCoreData
   import ExLog // この例ではログ出力に同作者のLog出力ライブラリExLogを利用している
   ...
       ExampleCoreData.initInstance { (status: ExCoreDataInitStatus<NSManagedObjectContext, Error>) in
           // ここノブロックは必ずUI Thread上での処理となるのでUIの更新が可能
           switch status{
           case .failure(let error):
               ExLog.error(error)
               ExLog.log("予期しないエラーが発生した")
               // UIにエラーを表示したいならここで何かUIを更新する処理を記載する
           case .initialized:
               ExLog.error("アプリ起動後にすでに初期化済みもしくは削除済みである")
               // 本来は複数箇所でExampleCoreData.initInstanceを呼び出すべきではないのでここが実行されることはないようにすること。
               // initInstanceでsuccessが呼ばれた後に別の箇所でcontextを取得したい場合は、ExampleCoreData.getContextで取得すること
           case .initializing:
               ExLog.error("アプリ起動後に別の箇所でExampleCoreData.initInstanceを呼び出してまだ初期化中である")
               // 本来は複数箇所でExampleCoreData.initInstanceを呼び出すべきではないのでここが実行されることはないようにすること。
               // initInstanceでsuccessが呼ばれた後に別の箇所でcontextを取得したい場合は、ExampleCoreData.getContextで取得すること
           case .success(let context):
               ExLog.log("初期化完了。作成されたcontextは次の通りである：\(context)")
               // contextの初期化が終わったので、ここでUIを更新すること。
               // 例えば、initInstanceを呼ぶ前にTableはrowを0にして読み込み中を表示するようにして、ここにきたらcontextのデータをfetchしてテーブルに設定するなど
           }
       }

   ```

   - 注意

     - initInstance は context を生成するときに、`NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)`を利用しているので、必ずメインスレッド上で実行すること(他のスレッドで実行すると failure が引数に設定されて completionHandler が呼び出される)。

3. initInstance の completionHandler が引数に success が設定されて呼ばれた以降で context を取得したい場合は、{ExCoreData を継承したクラス}#getContext で取得する

   ```swift
   guard let context = ExampleCoreData.getContext() else{
       // エラーとする
       return
   }
   ```

### ② 複数の DB ファイルを利用する方法

① と同じ様に別の ExCoreData を継承したクラスを作成するだけでそれぞれ独立して利用することができる。

### ③ NSManagedObject の簡単な利用手段

Entity のクラスファイルを Xcode の機能遠使って生成し、生成したクラスの親クラスが ExRecords になるように修正すれば利用可能になる。

#### ExRecords を継承したクラスの生成方法

1. Xcode の xcdatamodeld 拡張子のファイルを開いて、任意の[Class > Codegen > Manual/None]の Entity を作成する

2. 作成した Entity に対応するクラスを Xcode の機能を使って生成(xcdatamodeld 拡張子のファイルを開いている状態 > Editor > Create NSManagedObject Subclass... > 選択して進める)し、生成されたクラスファイル開き、ExRecords を継承するように修正する。

#### ExRecords を継承したクラスでできること

ExRecords のメソッドの Docs 参照。

## 注意事項

- {ExCoreData を継承したクラス}#initInstance で初期化された Context は静的変数として保存されるため、メモリを圧迫する点に注意。もちろん、ひとつかふたつなら特に問題なし。

- 本来 CoreData は SQLite 以外のストアタイプもサポートしているが、このライブラリでは　 SQLite のみサポートしている。変更したい場合は、CoreDataStore＃addPerssistentStored を直接編集する必要あり。

## Author

Jirokichi, kdy.developer@gmail.com

## License

ExCoreData is available under the MIT license. See the LICENSE file for more info.

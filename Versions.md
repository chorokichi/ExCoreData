# バージョン履歴

| Version | 詳細                                                                                                                                                                                                                                                      |
| ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0.1.0   | 初期バージョン                                                                                                                                                                                                                                            |
| 0.2.0   | ExConfig の追加。ExConfig はあらかじめ `ConfigCoreData#initConfig` を `AppDelegate#didFinishLaunchingWithOptions` で呼んでおけば利用可能。                                                                                                                |
| 0.2.1   | (1) ExRecord の fetchRecord の静的メソッド二つを新規追加した `ExRecordHandler` に複製した。将来的には ExRecord からそれらメソッドを削除する予定。(2) fetchOneRecord の context.fetch でのエラーをもみ消していたのを fatalError が出力されるように変更した |
| 0.2.2   | ExConfig#getStrictly を追加                                                                                                                                                                                                                               |

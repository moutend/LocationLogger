# DistanceTool

LocationLoggerで作成したCSVファイルを読み取り、基準点からの距離をメートル単位で表示します。

## システム要件

- Go 1.23+

## 使い方

```console
$ cd DistanceTool
$ go build
$ ./DistanceTool -latitude <緯度> -longitude <経度> <CSVファイルのパス>
```

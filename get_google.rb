# クラスインスタンスの作成
simple_http = SimpleHttp.new("google.co.jp", "80")

# get
puts simple_http.get("/")
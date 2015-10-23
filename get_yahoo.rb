# クラスインスタンスの作成
simple_http = SimpleHttp.new("yahoo.co.jp", "80")

# get
simple_http.get("/")

# うまくいかないケースはDNSの参照に失敗していることがほとんどです
# そのためPCからpingなどでIPアドレスを確認の上していすればうまくいきます
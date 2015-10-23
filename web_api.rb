# クラスインスタンスの作成
simple_http = SimpleHttp.new("[ip]", "[port]")
# 必ず必要
simple_http.http_version = "HTTP/1.1"

# get
puts simple_http.get("/[key]/slack/temp/[id]/20.44")
#puts simple_http.get("/[key]/twitter/hum/[id]/50")
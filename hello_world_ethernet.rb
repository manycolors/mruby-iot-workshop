# 80で待受
serv = TCPServer.open('192.168.0.0', 80) #DHCPなのでIPアドレスは関係なし

# buffer(通常そのままでいいです)
buf_len = 32

content = "<html><body>hello world!</body></html>"

loop do
  # 待ち受け開始
  c = serv.accept
  
  #####
  # おまじない的な(通常そのままでいいです)
  #####
  recv_text = nil
  while (recv_text.nil?)
    recv_text = c.recv(buf_len)
  end

  while (t = c.recv(buf_len))
    recv_text += t
  end
  #####

  # レスポンス送信
  c.send "HTTP/1.0 200 OK\r\n"
  c.send "Content-Length: #{content.length}\r\n"
  c.send "Content-Type: text/html\r\n"
  c.send "\r\n"
  c.send content
  
  # 待ち受け終了
  c.close
end

serv.close
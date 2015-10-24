# 温度計のクラスを貼り付け
# temp_bar.rbかtemp_bar_2.rbから
class BarometerBMP
  #Bosch BMP085/BMP180
  
  BMP_ADDRESS=0x77
  OSS = 0

  def initialize
    @ac1 = read_int16( 0xAA )
    @ac2 = read_int16( 0xAC )
    @ac3 = read_int16( 0xAE )
    @ac4 = read_uint16( 0xB0 )
    @ac5 = read_uint16( 0xB2 )
    @ac6 = read_uint16( 0xB4 )
    @b1 = read_int16( 0xB6 )
    @b2 = read_int16( 0xB8 )
    @mb = read_int16( 0xBA )
    @mc = read_int16( 0xBC )
    @md = read_int16( 0xBE )
    
    @temp = 0
    @press = 0

    #p "@ac1=#{@ac1}, @ac2=#{@ac2}, @ac3=#{@ac3}, "
  end

  def read_uint8( reg_addr )
    $wire.beginTransmission( BMP_ADDRESS )
    $wire.write( reg_addr )
    $wire.endTransmission()
    $wire.requestFrom( BMP_ADDRESS, 1 )
    value = $wire.read        
    return value
  end

  def read_uint16( reg_addr )
    hi = read_uint8( reg_addr )
    lo = read_uint8( reg_addr + 1 )
    value = hi*256 + lo
  end

  def read_int16( reg_addr )
    value = read_uint16( reg_addr )
    if value >= 32768
      value = -( 65536 - value )
    end
    return value
  end

  def write_uint8( reg_addr, value )
    $wire.beginTransmission( BMP_ADDRESS )
    $wire.write( reg_addr )
    $wire.write( value )
    $wire.endTransmission()
  end

  def calc
    #UT
    write_uint8( 0xF4, 0x2E )
    delay( 5 )
    ut = read_uint16( 0xF6 )
  
    #UP    
    write_uint8( 0xF4, 0x34 + (OSS<<6) )
    delay( 2 + (3<<OSS) )

    hi = read_uint8( 0xF6 )
    mi = read_uint8( 0xF7 )
    lo = read_uint8( 0xF8 )

    up = hi * 65536 + mi * 256 + lo
    up = up >> (8-OSS)

    #p "ut=#{ut}, up=#{up}"
  
    #temperature
    x1 = ( ut - @ac6 ) * @ac5 / 32768
    x2 = @mc * 2048 / ( x1 + @md )
    b5 = ( x1 + x2 ).to_i
    t = ( b5 + 8 ) / 16
    @temp = t.floor() / 10.0

    #pressure
    b6 = b5 - 4000
    
    x1 = ( @b2 * ( b6 * b6 / 2**12 ) ) / 2**11
    x2 = ( @ac2 * b6 ) / 2**11
    x3 = x1 + x2
    b3 = ( ( ( @ac1 * 4 + x3 ).to_i << OSS ) + 2 ) / 4
    b3 = b3.to_i
    #p "x1=#{x1}, x2=#{x2}, x3=#{x3}, b3=#{b3}"
    
    x1 = ( @ac3 * b6 ) / 2**13
    x2 = ( @b1 * ( b6 * b6 / 2**12 ) ) / 2**16
    x3 = ( ( x1 + x2 ) + 2 ) / 2**2
    b4 = ( @ac4 * ( x3 + 32768 ) ) / 2**15
    b4 = b4.to_i
    #p "x1=#{x1}, x2=#{x2}, x3=#{x3}, b4=#{b4}"
    
    b7 = ( up - b3 ) * ( 50000 >> OSS )
    b7 = b7.to_i
    #p "b7=#{b7}"
    if ( b7 < 0x80000000 )
      p = ( b7 * 2 ) / b4
    else
      p = ( b7 / b4 ) * 2
    end
    
    x1 = ( p / 2**8 ) * ( p / 2**8 )
    x1 = ( x1 * 3038 ) / 2**16
    x2 = ( -7357 * p ) / 2**16
    p += ( x1 + x2 + 3791 ) / 2**4
    @press = p.to_i
    
    return true    
  end

  def temperature
    return @temp
  end

  def pressure
    return @press
  end
end

$wire = Wire.new( 0x0, Wire::DutyCycle_2 )  

sensor = BarometerBMP.new

serv = TCPServer.open('192.168.0.0', 80) #IPアドレスは関係なし
buf_len = 32

temp = Array.new

# グラフ用に10個埋める
10.times do
  sensor.calc
  p temp << sensor.temperature
end

content = Array.new

# コンテンツ固定箇所前半
content[0] = "<html>"
content[0] += "<head>"
content[0] += "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />"
content[0] += "<script type=\"text/javascript\" src=\"https://www.google.com/jsapi\"></script>"
content[0] += "<script type=\"text/javascript\">"
content[0] += "  google.load('visualization', '1', {'packages':['corechart']});     "
content[0] += "  google.setOnLoadCallback(drawChart);"
content[0] += "  function drawChart() {      "
content[0] += "    var data = google.visualization.arrayToDataTable(["
content[0] += "      ['秒数', '温度'],"
# コンテンツ固定箇所後半
content[2] = "    ]);"
content[2] += "    var options = {"
content[2] += "      title: '温度の推移'"
content[2] += "     };     "
content[2] += "    var chart = new google.visualization.LineChart(document.getElementById('chart_div'));"
content[2] += "    chart.draw(data, options);"
content[2] += "  }"
content[2] += "</script>"
content[2] += "</head>"
content[2] += "<body>"
content[2] += "  <div id=\"chart_div\" style=\"width: 100%; height: 350px\"></div>  "
content[2] += "</body>"
content[2] += "</html>"



loop do
  content[1] = ""
  c = serv.accept

  recv_text = nil
  while (recv_text.nil?)
    recv_text = c.recv(buf_len)
  end

  while (t = c.recv(buf_len))
    recv_text += t
  end
  
  temp.shift
  
  #####################
  # temp_bar_2の人は書き換える必要あり
  # 考えてみてください
  #####################
  sensor.calc
  temp << sensor.temperature

  counter = temp.size
  temp.each do |t|
    counter -= 1
    content[1] += "['-#{counter}', #{t}],"
  end

  # レスポンス送信
  c.send "HTTP/1.0 200 OK\r\n"
  c.send "Content-Length: #{content.join.length}\r\n"
  c.send "Content-Type: text/html\r\n"
  c.send "\r\n"
  c.send content.join
  
  c.close
end

serv.close
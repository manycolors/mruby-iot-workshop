# 点等
analogWrite(D8, 255)
delay(1000)

# 消灯
analogWrite(D8, 0)
delay(1000)

# 暗い→明るい
10.times do
  255.times do |i|
   analogWrite(D8, i)
   delay(10)
  end
end
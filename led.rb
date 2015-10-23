# 点等
digitalWrite(D8, 1)
delay(1000)

# 消灯
digitalWrite(D8, 0)
delay(1000)

# 1秒おきに点滅
status = 0
100.times do
  puts status ^= 1
  digitalWrite(D8, status)
  delay(1000)
end

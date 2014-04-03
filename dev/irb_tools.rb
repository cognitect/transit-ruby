def time
  start = Time.now
  yield
  puts "Elapsed: #{Time.now - start}"
end

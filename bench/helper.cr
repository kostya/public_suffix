require "../src/public_suffix"

# Initialize
t = Time.now
PublicSuffixList = PublicSuffix::List.default
p "instant list: #{PublicSuffixList.size}, #{Time.now - t}"

def test(name, times)
  t = Time.now
  c = 0
  times.times do
    c += 1 if yield
  end
  puts "#{name}: #{c == times ? "ok" : "fail"} = #{Time.now - t}"
end

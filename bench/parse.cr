require "./helper"

DOMAINS = %w(
  example.de
  www.subdomain.example.de
  one.two.three.four.five.example.de
  one.two.three.four.five.example.bd
  one.two.three.four.five.www.ck
  www.example.ac
  www.example.zone
  one.two.three.four.five.example.beep.pl
  one.two.three.four.five.example.now.sh
  www.yokoshibahikari.chiba.jp
  www.example.it
  Www.EXAMPLE.CO.UK
)

N = (ARGV[0]? || 10_000).to_i
ignore_private = (ARGV[1]? == "1")

t = Time.now
DOMAINS.each do |domain|
  test(domain, N) do
    PublicSuffix.parse(domain, ignore_private: ignore_private)
  end
end
p Time.now - t

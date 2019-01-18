require "./helper"

N = (ARGV[0]? || 100_000).to_i

RULES = [
  {"com", "google.com"},
  {"go.ci", "www.jopen-33.go.ci"},
  {"*.ck", "www.kross.pendal.ck"},
  {"!www.ck", "www.ck"},
]

t = Time.now

RULES.each do |rule, domain|
  r = PublicSuffix::Rule.factory(rule)
  test("#{rule} - #{domain}", N) do
    r.decompose(domain)
  end
end

p Time.now - t

require "./spec_helper"

describe PublicSuffix do
  it do
    domain = PublicSuffix.parse("www.example.blogspot.com")
    domain.tld.should eq "blogspot.com"
  end

  it do
    domain = PublicSuffix.parse("example.com")
    domain.to_tuple.should eq({nil, "example", "com"})

    domain = PublicSuffix.parse("example.co.uk")
    domain.to_tuple.should eq({nil, "example", "co.uk"})
  end

  context "parse" do
    it { PublicSuffix.parse("alpha.example.com").to_tuple.should eq({"alpha", "example", "com"}) }
    it { PublicSuffix.parse("alpha.example.co.uk").to_tuple.should eq({"alpha", "example", "co.uk"}) }

    it { PublicSuffix.parse("one.two.example.com").to_tuple.should eq({"one.two", "example", "com"}) }
    it { PublicSuffix.parse("one.two.example.co.uk").to_tuple.should eq({"one.two", "example", "co.uk"}) }

    it { PublicSuffix.parse("www.example.com.").to_tuple.should eq({"www", "example", "com"}) }
    it { PublicSuffix.parse("example.tldnotlisted").to_tuple.should eq({nil, "example", "tldnotlisted"}) }

    it "custom" do
      list = PublicSuffix::List.new
      list.add PublicSuffix::Rule.factory("test")

      PublicSuffix.parse("www.example.test", list: list).to_tuple.should eq({"www", "example", "test"})
    end
  end

  context "valid?" do
    it { PublicSuffix.valid?("google.com").should be_true }
    it { PublicSuffix.valid?("www.google.com").should be_true }
    it { PublicSuffix.valid?("google.co.uk").should be_true }
    it { PublicSuffix.valid?("www.google.co.uk").should be_true }

    it { PublicSuffix.valid?("google.tldnotlisted").should be_true }
    it { PublicSuffix.valid?("www.google.tldnotlisted").should be_true }
  end

  context "domain" do
    it { PublicSuffix.domain("google.com").should eq "google.com" }
    it { PublicSuffix.domain("www.google.com").should eq "google.com" }
    it { PublicSuffix.domain("google.co.uk").should eq "google.co.uk" }
    it { PublicSuffix.domain("www.google.co.uk").should eq "google.co.uk" }
  end

  it("not listed") { PublicSuffix.domain("example.tldnotlisted").should eq "example.tldnotlisted" }
  it("unallowed name") { PublicSuffix.domain("example.kh").should eq nil }

  context "blank sld" do
    it { PublicSuffix.domain("com").should eq nil }
    it { PublicSuffix.domain(".com").should eq nil }
  end

  context "normalize" do
    [
      ["com", "com"],
      ["example.com", "example.com"],
      ["www.example.com", "www.example.com"],

      ["example.com.", "example.com"],  # strip FQDN
      [" example.com ", "example.com"], # strip spaces
      ["Example.COM", "example.com"],   # downcase
    ].each do |(input, output)|
      it { PublicSuffix.normalize(input).should eq output }
    end
  end

  context "parse error" do
    it { expect_raises(PublicSuffix::DomainNotAllowed, /example\.kh/) { PublicSuffix.parse("example.kh") } }
    it { expect_raises(PublicSuffix::DomainInvalid, %r{http://google\.com}) { PublicSuffix.parse("http://google.com") } }
  end

  context "normalize error" do
    it { expect_raises(PublicSuffix::DomainInvalid, "Name is blank") { PublicSuffix.normalize("") } }
    it { expect_raises(PublicSuffix::DomainInvalid, "scheme") { PublicSuffix.normalize("https://google.com") } }
    it { expect_raises(PublicSuffix::DomainInvalid, "Name starts with a dot") { PublicSuffix.normalize(".google.com") } }
  end

  it "disable private domains" do
    data = File.read(PublicSuffix::List::DEFAULT_LIST_PATH)
    begin
      PublicSuffix::List.default = PublicSuffix::List.parse(data, private_domains: false)
      domain = PublicSuffix.parse("www.example.blogspot.com")
      domain.tld.should eq "com"
    ensure
      PublicSuffix::List.default = nil
    end
  end
end

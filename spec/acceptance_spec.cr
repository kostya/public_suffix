require "./spec_helper"

describe PublicSuffix do
  [
    {"example.com", "example.com", {nil, "example", "com"}},
    {"foo.example.com", "example.com", {"foo", "example", "com"}},

    {"verybritish.co.uk", "verybritish.co.uk", {nil, "verybritish", "co.uk"}},
    {"foo.verybritish.co.uk", "verybritish.co.uk", {"foo", "verybritish", "co.uk"}},

    {"parliament.uk", "parliament.uk", {nil, "parliament", "uk"}},
    {"foo.parliament.uk", "parliament.uk", {"foo", "parliament", "uk"}},
  ].each do |input, domain, results|
    it "valid #{input}" do
      parsed = PublicSuffix.parse(input)
      parsed.to_tuple.should eq results
      PublicSuffix.domain(input).should eq domain
      PublicSuffix.valid?(input).should be_true
    end
  end

  [
    {"nic.kh", PublicSuffix::DomainNotAllowed},
    {"", PublicSuffix::DomainInvalid},
    {"  ", PublicSuffix::DomainInvalid},
  ].each do |name, error|
    it "invalid #{name}" do
      expect_raises(error) { PublicSuffix.parse(name) }
      PublicSuffix.valid?(name).should be_false
    end
  end

  [
    {"www. .com", true},
    {"foo.co..uk", true},
    {"goo,gle.com", true},
    {"-google.com", true},
    {"google-.com", true},

    # This case was covered in GH-15.
    # I decided to cover this case because it's not easily reproducible with URI.parse
    # and can lead to several false positives.
    {"http://google.com", false},
  ].each do |name, expected|
    it "rejected #{name}" do
      PublicSuffix.valid?(name).should eq expected
    end
  end

  context "case" do
    [
      {"Www.google.com", {"www", "google", "com"}},
      {"www.Google.com", {"www", "google", "com"}},
      {"www.google.Com", {"www", "google", "com"}},
    ].each do |name, results|
      it "parse #{name}" do
        domain = PublicSuffix.parse(name)
        domain.to_tuple.should eq results
      end

      it "valid #{name}" do
        PublicSuffix.valid?(name).should be_true
      end
    end
  end

  [
    {"blogspot.com", true, "blogspot.com"},
    {"blogspot.com", false, nil},
    {"subdomain.blogspot.com", true, "blogspot.com"},
    {"subdomain.blogspot.com", false, "subdomain.blogspot.com"},
  ].each do |given, ignore_private, expected|
    it "ignore #{given}" do
      PublicSuffix.domain(given, ignore_private: ignore_private).should eq expected
    end

    it "valid #{given}" do
      PublicSuffix.valid?(given, ignore_private: ignore_private).should eq !expected.nil?
    end
  end
end

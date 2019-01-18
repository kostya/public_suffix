require "./spec_helper"

describe PublicSuffix::Rule do
  context "factory" do
    it { PublicSuffix::Rule.factory("com").is_a?(PublicSuffix::Rule::Normal).should be_true }
    it { PublicSuffix::Rule.factory("verona.it").is_a?(PublicSuffix::Rule::Normal).should be_true }
    it { PublicSuffix::Rule.factory("!british-library.uk").is_a?(PublicSuffix::Rule::Exception).should be_true }
    it { PublicSuffix::Rule.factory("*.do").is_a?(PublicSuffix::Rule::Wildcard).should be_true }
    it { PublicSuffix::Rule.factory("*.sch.uk").is_a?(PublicSuffix::Rule::Wildcard).should be_true }
    it do
      default = PublicSuffix::Rule.default
      default.should eq PublicSuffix::Rule::Wildcard.build("*")

      default.decompose("example.tldnotlisted").should eq({"example", "tldnotlisted"})
      default.decompose("www.example.tldnotlisted").should eq({"www.example", "tldnotlisted"})
    end
  end

  context "Normal" do
    it do
      rule = PublicSuffix::Rule::Normal.build("verona.it")
      rule.value.should eq "verona.it"
      rule.rule.should eq "verona.it"
    end

    it do
      PublicSuffix::Rule::Normal.build("com").length.should eq 1
      PublicSuffix::Rule::Normal.build("co.com").length.should eq 2
      PublicSuffix::Rule::Normal.build("mx.co.com").length.should eq 3
    end

    it do
      PublicSuffix::Rule::Normal.build("com").parts.should eq %w(com)
      PublicSuffix::Rule::Normal.build("co.com").parts.should eq %w(co com)
      PublicSuffix::Rule::Normal.build("mx.co.com").parts.should eq %w(mx co com)
    end

    it do
      PublicSuffix::Rule::Normal.build("com").decompose("com").should eq({nil, nil})
      PublicSuffix::Rule::Normal.build("com").decompose("example.com").should eq({"example", "com"})
      PublicSuffix::Rule::Normal.build("com").decompose("foo.example.com").should eq({"foo.example", "com"})
    end
  end

  context "Exception" do
    it do
      rule = PublicSuffix::Rule::Exception.build("!british-library.uk")
      rule.value.should eq "british-library.uk"
      rule.rule.should eq "!british-library.uk"
    end

    it do
      PublicSuffix::Rule::Exception.build("!british-library.uk").length.should eq 2
      PublicSuffix::Rule::Exception.build("!foo.british-library.uk").length.should eq 3
    end

    it do
      PublicSuffix::Rule::Exception.build("!british-library.uk").parts.should eq %w(uk)
      PublicSuffix::Rule::Exception.build("!metro.tokyo.jp").parts.should eq %w(tokyo jp)
    end

    it do
      PublicSuffix::Rule::Exception.build("!british-library.uk").decompose("uk").should eq({nil, nil})
      PublicSuffix::Rule::Exception.build("!british-library.uk").decompose("british-library.uk").should eq({"british-library", "uk"})
      PublicSuffix::Rule::Exception.build("!british-library.uk").decompose("foo.british-library.uk").should eq({"foo.british-library", "uk"})
    end
  end

  context "Wildcard" do
    it do
      rule = PublicSuffix::Rule::Wildcard.build("*.aichi.jp")
      rule.value.should eq "aichi.jp"
      rule.rule.should eq "*.aichi.jp"
    end

    it do
      PublicSuffix::Rule::Wildcard.build("*.uk").length.should eq 2
      PublicSuffix::Rule::Wildcard.build("*.co.uk").length.should eq 3
    end

    it do
      PublicSuffix::Rule::Wildcard.build("*.uk").parts.should eq %w(uk)
      PublicSuffix::Rule::Wildcard.build("*.co.uk").parts.should eq %w(co uk)
    end

    it do
      PublicSuffix::Rule::Wildcard.build("*.do").decompose("nic.do").should eq({nil, nil})
      PublicSuffix::Rule::Wildcard.build("*.uk").decompose("google.co.uk").should eq({"google", "co.uk"})
      PublicSuffix::Rule::Wildcard.build("*.uk").decompose("foo.google.co.uk").should eq({"foo.google", "co.uk"})
    end
  end

  context "Base" do
    [
      # standard match
      {PublicSuffix::Rule.factory("uk"), "uk", true},
      {PublicSuffix::Rule.factory("uk"), "example.uk", true},
      {PublicSuffix::Rule.factory("uk"), "example.co.uk", true},
      {PublicSuffix::Rule.factory("co.uk"), "example.co.uk", true},

      # FIXME
      # [PublicSuffix::Rule.factory("*.com"), "com", false],
      {PublicSuffix::Rule.factory("*.com"), "example.com", true},
      {PublicSuffix::Rule.factory("*.com"), "foo.example.com", true},
      {PublicSuffix::Rule.factory("!example.com"), "com", false},
      {PublicSuffix::Rule.factory("!example.com"), "example.com", true},
      {PublicSuffix::Rule.factory("!example.com"), "foo.example.com", true},

      # TLD mismatch
      {PublicSuffix::Rule.factory("gk"), "example.uk", false},
      {PublicSuffix::Rule.factory("gk"), "example.co.uk", false},
      {PublicSuffix::Rule.factory("co.uk"), "uk", false},

      # general mismatch
      {PublicSuffix::Rule.factory("uk.co"), "example.co.uk", false},
      {PublicSuffix::Rule.factory("go.uk"), "example.co.uk", false},
      {PublicSuffix::Rule.factory("co.uk"), "uk", false},

      # partial matches/mismatches
      {PublicSuffix::Rule.factory("co"), "example.co.uk", false},
      {PublicSuffix::Rule.factory("example"), "example.uk", false},
      {PublicSuffix::Rule.factory("le.it"), "example.it", false},
      {PublicSuffix::Rule.factory("le.it"), "le.it", true},
      {PublicSuffix::Rule.factory("le.it"), "foo.le.it", true},

    ].each do |rule, input, expected|
      it { rule.match?(input).should eq expected }
    end
  end
end

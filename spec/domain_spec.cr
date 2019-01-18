require "./spec_helper"

describe PublicSuffix do
  context "name_to_labels" do
    it { PublicSuffix::Domain.name_to_labels("someone.spaces.live.com").should eq %w(someone spaces live com) }
    it { PublicSuffix::Domain.name_to_labels("leontina23samiko.wiki.zoho.com").should eq %w(leontina23samiko wiki zoho com) }
  end

  context "init" do
    it { PublicSuffix::Domain.new("com", "google", "www").tld.should eq "com" }
    it { PublicSuffix::Domain.new("com", "google", "www").sld.should eq "google" }
    it { PublicSuffix::Domain.new("com", "google", "www").trd.should eq "www" }
  end

  context "to_tuple" do
    it { PublicSuffix::Domain.new("com").to_tuple.should eq({nil, nil, "com"}) }
    it { PublicSuffix::Domain.new("com", "google").to_tuple.should eq({nil, "google", "com"}) }
    it { PublicSuffix::Domain.new("com", "google", "www").to_tuple.should eq({"www", "google", "com"}) }
  end

  context "to_s" do
    it { PublicSuffix::Domain.new("com").to_s.should eq "com" }
    it { PublicSuffix::Domain.new("com", "google").to_s.should eq "google.com" }
    it { PublicSuffix::Domain.new("com", "google", "www").to_s.should eq "www.google.com" }
  end

  context "domain" do
    it { PublicSuffix::Domain.new("com").domain.should eq nil }
    it { PublicSuffix::Domain.new("tldnotlisted").domain.should eq nil }

    it { PublicSuffix::Domain.new("com", "google").domain.should eq "google.com" }
    it { PublicSuffix::Domain.new("tldnotlisted", "google").domain.should eq "google.tldnotlisted" }

    it { PublicSuffix::Domain.new("com", "google", "www").domain.should eq "google.com" }
    it { PublicSuffix::Domain.new("tldnotlisted", "google", "www").domain.should eq "google.tldnotlisted" }
  end

  context "subdomain" do
    it { PublicSuffix::Domain.new("com").subdomain.should eq nil }
    it { PublicSuffix::Domain.new("tldnotlisted").subdomain.should eq nil }

    it { PublicSuffix::Domain.new("com", "google").subdomain.should eq nil }
    it { PublicSuffix::Domain.new("tldnotlisted", "google").subdomain.should eq nil }

    it { PublicSuffix::Domain.new("com", "google", "www").subdomain.should eq "www.google.com" }
    it { PublicSuffix::Domain.new("tldnotlisted", "google", "www").subdomain.should eq "www.google.tldnotlisted" }
  end

  context "domain?" do
    it { PublicSuffix::Domain.new("com").domain?.should eq false }
    it { PublicSuffix::Domain.new("tldnotlisted").domain?.should eq false }

    it { PublicSuffix::Domain.new("com", "google").domain?.should eq true }
    it { PublicSuffix::Domain.new("tldnotlisted", "google").domain?.should eq true }

    it { PublicSuffix::Domain.new("com", "google", "www").domain?.should eq true }
    it { PublicSuffix::Domain.new("tldnotlisted", "google", "www").domain?.should eq true }
  end
end

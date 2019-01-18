require "./spec_helper"

LIST = PublicSuffix::List.parse(<<-EOS)
// com : http://en.wikipedia.org/wiki/.com
com

// uk : http://en.wikipedia.org/wiki/.uk
*.uk
*.sch.uk
!bl.uk
!british-library.uk
EOS

describe PublicSuffix do
  context "parse" do
    it do
      list = PublicSuffix::List.parse(<<-EOS)
alpha
beta
EOS
      list.rules.size.should eq 2
      list.rules["alpha"].should eq PublicSuffix::Rule.factory("alpha")
    end
  end

  context "find" do
    list = PublicSuffix::List.parse(<<-EOS)
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// ===BEGIN ICANN DOMAINS===

// com
com

// uk
*.uk
*.sch.uk
!bl.uk
!british-library.uk

// io
io

// ===END ICANN DOMAINS===
// ===BEGIN PRIVATE DOMAINS===

// Google, Inc.
blogspot.com

// ===END PRIVATE DOMAINS===
EOS

    # match IANA
    it { list.find("example.com").should eq PublicSuffix::Rule.factory("com") }
    it { list.find("foo.example.com").should eq PublicSuffix::Rule.factory("com") }

    # match wildcard
    it { list.find("example.uk").should eq PublicSuffix::Rule.factory("*.uk") }
    it { list.find("example.co.uk").should eq PublicSuffix::Rule.factory("*.uk") }
    it { list.find("foo.example.co.uk").should eq PublicSuffix::Rule.factory("*.uk") }

    # match exception
    it { list.find("british-library.uk").should eq PublicSuffix::Rule.factory("!british-library.uk") }
    it { list.find("foo.british-library.uk").should eq PublicSuffix::Rule.factory("!british-library.uk") }

    # match default rule
    it { list.find("test").should eq PublicSuffix::Rule.default }
    it { list.find("example.test").should eq PublicSuffix::Rule.default }
    it { list.find("foo.example.test").should eq PublicSuffix::Rule.default }

    # match private
    it { list.find("blogspot.com").should eq PublicSuffix::Rule.factory("blogspot.com", _private: true) }
    it { list.find("foo.blogspot.com").should eq PublicSuffix::Rule.factory("blogspot.com", _private: true) }
  end

  context "filter" do
    it { LIST.filter("british-library.uk").size.should eq 2 }
    it { LIST.filter("").size.should eq 0 }
    it { LIST.filter(" ").size.should eq 0 }
  end

  context "parse & find" do
    list = PublicSuffix::List.parse(<<-EOS)
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// ===BEGIN ICANN DOMAINS===

// com
com

// uk
*.uk
!british-library.uk

// ===END ICANN DOMAINS===
// ===BEGIN PRIVATE DOMAINS===

// Google, Inc.
blogspot.com

// ===END PRIVATE DOMAINS===
EOS

    it { list.size.should eq 4 }

    it { list.rules["com"].should eq PublicSuffix::Rule.factory("com") }
    it { list.rules["uk"].should eq PublicSuffix::Rule.factory("*.uk") }
    it { list.rules["british-library.uk"].should eq PublicSuffix::Rule.factory("!british-library.uk") }
    it { list.rules["blogspot.com"].should eq PublicSuffix::Rule.factory("blogspot.com", _private: true) }

    # private domains
    it { list.find("com")._private.should eq false }
    it { list.find("blogspot.com")._private.should eq true }
  end

  context "ignore_private" do
    list = PublicSuffix::List.new
    list.add r1 = PublicSuffix::Rule.factory("io")
    list.add r2 = PublicSuffix::Rule.factory("example.io", _private: true)

    it { list.filter("foo.io").should eq [r1] }
    it { list.filter("example.io").should eq [r1, r2] }
    it { list.filter("foo.example.io").should eq [r1, r2] }

    it { list.filter("foo.io", ignore_private: false).should eq [r1] }
    it { list.filter("example.io", ignore_private: false).should eq [r1, r2] }
    it { list.filter("foo.example.io", ignore_private: false).should eq [r1, r2] }

    it { list.filter("foo.io", ignore_private: true).should eq [r1] }
    it { list.filter("example.io", ignore_private: true).should eq [r1] }
    it { list.filter("foo.example.io", ignore_private: true).should eq [r1] }
  end

  context "recreate index" do
    list = PublicSuffix::List.parse("com")

    it { list.find("google.com").should eq PublicSuffix::Rule.factory("com") }
    it { list.find("google.net").should eq list.default_rule }

    list.add PublicSuffix::Rule.factory("net")

    it { list.find("google.com").should eq PublicSuffix::Rule.factory("com") }
    it { list.find("google.net").should eq PublicSuffix::Rule.factory("net") }
  end
end

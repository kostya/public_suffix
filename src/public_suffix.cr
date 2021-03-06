require "./public_suffix/*"

module PublicSuffix
  DOT  = '.'
  BANG = '!'
  STAR = '*'

  # Parses +name+ and returns the {PublicSuffix::Domain} instance.
  #
  # @example Parse a valid domain
  #   PublicSuffix.parse("google.com")
  #   # => #<PublicSuffix::Domain:0x007fec2e51e588 @sld="google", @tld="com", @trd=nil>
  #
  # @example Parse a valid subdomain
  #   PublicSuffix.parse("www.google.com")
  #   # => #<PublicSuffix::Domain:0x007fec276d4cf8 @sld="google", @tld="com", @trd="www">
  #
  # @example Parse a fully qualified domain
  #   PublicSuffix.parse("google.com.")
  #   # => #<PublicSuffix::Domain:0x007fec257caf38 @sld="google", @tld="com", @trd=nil>
  #
  # @example Parse a fully qualified domain (subdomain)
  #   PublicSuffix.parse("www.google.com.")
  #   # => #<PublicSuffix::Domain:0x007fec27b6bca8 @sld="google", @tld="com", @trd="www">
  #
  # @example Parse an invalid (unlisted) domain
  #   PublicSuffix.parse("x.yz")
  #   # => #<PublicSuffix::Domain:0x007fec2f49bec0 @sld="x", @tld="yz", @trd=nil>
  #
  # @example Parse an invalid (unlisted) domain with strict checking (without applying the default * rule)
  #   PublicSuffix.parse("x.yz", default_rule: nil)
  #   # => PublicSuffix::DomainInvalid: `x.yz` is not a valid domain
  #
  # @example Parse an URL (not supported, only domains)
  #   PublicSuffix.parse("http://www.google.com")
  #   # => PublicSuffix::DomainInvalid: http://www.google.com is not expected to contain a scheme
  #
  #
  # @param  [String, #to_s] name The domain name or fully qualified domain name to parse.
  # @param  [PublicSuffix::List] list The rule list to search, defaults to the default {PublicSuffix::List}
  # @param  [Boolean] ignore_private
  # @return [PublicSuffix::Domain]
  #
  # @raise [PublicSuffix::DomainInvalid]
  #   If domain is not a valid domain.
  # @raise [PublicSuffix::DomainNotAllowed]
  #   If a rule for +domain+ is found, but the rule doesn't allow +domain+.
  def self.parse(name : String, list = List.default, default_rule = list.default_rule, ignore_private = false)
    what = normalize(name)

    rule = list.find(what, default: default_rule, ignore_private: ignore_private)

    unless rule
      raise DomainInvalid.new("`#{what}` is not a valid domain")
    end

    left, right = rule.decompose(what)
    unless right
      raise DomainNotAllowed.new("`#{what}` is not allowed according to Registry policy")
    end

    decompose(what, left, right)
  end

  # Checks whether +domain+ is assigned and allowed, without actually parsing it.
  #
  # This method doesn't care whether domain is a domain or subdomain.
  # The validation is performed using the default {PublicSuffix::List}.
  #
  # @example Validate a valid domain
  #   PublicSuffix.valid?("example.com")
  #   # => true
  #
  # @example Validate a valid subdomain
  #   PublicSuffix.valid?("www.example.com")
  #   # => true
  #
  # @example Validate a not-listed domain
  #   PublicSuffix.valid?("example.tldnotlisted")
  #   # => true
  #
  # @example Validate a not-listed domain with strict checking (without applying the default * rule)
  #   PublicSuffix.valid?("example.tldnotlisted")
  #   # => true
  #   PublicSuffix.valid?("example.tldnotlisted", default_rule: nil)
  #   # => false
  #
  # @example Validate a fully qualified domain
  #   PublicSuffix.valid?("google.com.")
  #   # => true
  #   PublicSuffix.valid?("www.google.com.")
  #   # => true
  #
  # @example Check an URL (which is not a valid domain)
  #   PublicSuffix.valid?("http://www.example.com")
  #   # => false
  #
  #
  # @param  [String, #to_s] name The domain name or fully qualified domain name to validate.
  # @param  [Boolean] ignore_private
  # @return [Boolean]
  def self.valid?(name : String, list = List.default, default_rule = list.default_rule, ignore_private = false)
    what = begin
      normalize(name)
    rescue DomainInvalid
      return false
    end

    rule = list.find(what, default: default_rule, ignore_private: ignore_private)

    rule && !rule.decompose(what).last.nil?
  end

  # Attempt to parse the name and returns the domain, if valid.
  #
  # This method doesn't raise. Instead, it returns nil if the domain is not valid for whatever reason.
  #
  # @param  [String, #to_s] name The domain name or fully qualified domain name to parse.
  # @param  [PublicSuffix::List] list The rule list to search, defaults to the default {PublicSuffix::List}
  # @param  [Boolean] ignore_private
  # @return [String]
  def self.domain(name, **options)
    parse(name, **options).domain
  rescue PublicSuffix::Error
    nil
  end

  private def self.decompose(name, left, right)
    sld, trd = if left
                 parts = left.split(DOT)
                 # If we have 0 parts left, there is just a tld and no domain or subdomain
                 # If we have 1 part  left, there is just a tld, domain and not subdomain
                 # If we have 2 parts left, the last part is the domain, the other parts (combined) are the subdomain
                 _sld = parts.empty? ? nil : parts.pop
                 _trd = parts.empty? ? nil : parts.join(DOT)
                 {_sld, _trd}
               else
                 {nil, nil}
               end

    Domain.new(right, sld, trd)
  end

  # Pretend we know how to deal with user input.
  def self.normalize(name)
    name = name.strip
    name = name.chomp(DOT)
    name = name.downcase

    raise DomainInvalid.new("Name is blank") if name.empty?
    raise DomainInvalid.new("Name starts with a dot") if name.starts_with?(DOT)
    raise DomainInvalid.new("%s is not expected to contain a scheme" % name) if name.includes?("://")
    name
  end
end

# = Public Suffix
#
# Domain name parser based on the Public Suffix List.
#
# Copyright (c) 2009-2017 Simone Carletti <weppos@weppos.net>

module PublicSuffix
  # A Rule is a special object which holds a single definition
  # of the Public Suffix List.
  #
  # There are 3 types of rules, each one represented by a specific
  # subclass within the +PublicSuffix::Rule+ namespace.
  #
  # To create a new Rule, use the {PublicSuffix::Rule#factory} method.
  #
  #   PublicSuffix::Rule.factory("ar")
  #   # => #<PublicSuffix::Rule::Normal>
  #
  module Rule
    # @api internal
    # = Abstract rule class
    #
    # This represent the base class for a Rule definition
    # in the {Public Suffix List}[https://publicsuffix.org].
    #
    # This is intended to be an Abstract class
    # and you shouldn't create a direct instance. The only purpose
    # of this class is to expose a common interface
    # for all the available subclasses.
    #
    # * {PublicSuffix::Rule::Normal}
    # * {PublicSuffix::Rule::Exception}
    # * {PublicSuffix::Rule::Wildcard}
    #
    # ## Properties
    #
    # A rule is composed by 4 properties:
    #
    # value   - A normalized version of the rule name.
    #           The normalization process depends on rule tpe.
    #
    # Here's an example
    #
    #   PublicSuffix::Rule.factory("*.google.com")
    #   #<PublicSuffix::Rule::Wildcard:0x1015c14b0
    #       @value="google.com"
    #   >
    #
    # ## Rule Creation
    #
    # The best way to create a new rule is passing the rule name
    # to the <tt>PublicSuffix::Rule.factory</tt> method.
    #
    #   PublicSuffix::Rule.factory("com")
    #   # => PublicSuffix::Rule::Normal
    #
    #   PublicSuffix::Rule.factory("*.com")
    #   # => PublicSuffix::Rule::Wildcard
    #
    # This method will detect the rule type and create an instance
    # from the proper rule class.
    #
    # ## Rule Usage
    #
    # A rule describes the composition of a domain name and explains how to tokenize
    # the name into tld, sld and trd.
    #
    # To use a rule, you first need to be sure the name you want to tokenize
    # can be handled by the current rule.
    # You can use the <tt>#match?</tt> method.
    #
    #   rule = PublicSuffix::Rule.factory("com")
    #
    #   rule.match?("google.com")
    #   # => true
    #
    #   rule.match?("google.com")
    #   # => false
    #
    # Rule order is significant. A name can match more than one rule.
    # See the {Public Suffix Documentation}[http://publicsuffix.org/format/]
    # to learn more about rule priority.
    #
    # When you have the right rule, you can use it to tokenize the domain name.
    #
    #   rule = PublicSuffix::Rule.factory("com")
    #
    #   rule.decompose("google.com")
    #   # => ["google", "com"]
    #
    #   rule.decompose("www.google.com")
    #   # => ["www.google", "com"]
    #
    # @abstract
    #
    abstract struct Base
      # @return [String] the rule definition
      getter value : String

      # @return [Int32] the length of the rule
      getter length : Int32

      # @return [Boolean] true if the rule is a private domain
      getter _private : Bool

      # Initializes a new rule from the content.
      #
      # @param  content [String] the content of the rule
      # @param  private [Boolean]
      def self.build(content, _private = false)
        new(value: content, _private: _private)
      end

      # Initializes a new rule.
      #
      # @param  value [String]
      # @param  private [Boolean]
      def initialize(@value : String, length : Int32? = nil, @_private = false)
        @length = length || @value.count(DOT) + 1
      end

      # Checks if this rule matches +name+.
      #
      # A domain name is said to match a rule if and only if
      # all of the following conditions are met:
      #
      # - When the domain and rule are split into corresponding labels,
      #   that the domain contains as many or more labels than the rule.
      # - Beginning with the right-most labels of both the domain and the rule,
      #   and continuing for all labels in the rule, one finds that for every pair,
      #   either they are identical, or that the label from the rule is "*".
      #
      # @see https://publicsuffix.org/list/
      #
      # @example
      #   PublicSuffix::Rule.factory("com").match?("example.com")
      #   # => true
      #   PublicSuffix::Rule.factory("com").match?("example.net")
      #   # => false
      #
      # @param  name [String] the domain name to check
      # @return [Boolean]
      def match?(name)
        # Note: it works because of the assumption there are no
        # rules like foo.*.com. If the assumption is incorrect,
        # we need to properly walk the input and skip parts according
        # to wildcard component.
        diff = name.chomp(value)
        diff.empty? || diff[-1] == DOT
      end

      abstract def parts
      abstract def decompose(domain : String) : Tuple(String?, String?)
    end

    # Normal represents a standard rule (e.g. com).
    struct Normal < Base
      # Gets the original rule definition.
      #
      # @return [String] The rule definition.
      def rule
        value
      end

      # dot-split rule value and returns all rule parts
      # in the order they appear in the value.
      #
      # @return [Array<String>]
      def parts
        @value.split(DOT)
      end

      # Decomposes the domain name according to rule properties.
      #
      # @param  [String, #to_s] name The domain name to decompose
      # @return [Array<String>] The array with [trd + sld, tld].
      def decompose(domain : String) : Tuple(String?, String?)
        value = @value
        return {nil, nil} unless domain.ends_with?(value)

        dbs = domain.size
        vbs = value.size
        index = dbs - vbs - 1
        return {nil, nil} if index <= 0

        if domain[index] == DOT
          {domain[0, index], value}
        else
          {nil, nil}
        end
      end
    end

    # Wildcard represents a wildcard rule (e.g. *.co.uk).
    struct Wildcard < Base
      # Initializes a new rule from the content.
      #
      # @param  content [String] the content of the rule
      # @param  private [Boolean]
      def self.build(content, _private = false)
        s = content.size > 2 ? content.to_s[2..-1] : ""
        new(value: s, _private: _private)
      end

      # Initializes a new rule.
      #
      # @param  value [String]
      # @param  private [Boolean]
      def initialize(value : String, length : Int32? = nil, _private = false)
        super(value: value, length: length, _private: _private)
        unless length
          @length += 1 # * counts as 1
        end
      end

      # Gets the original rule definition.
      #
      # @return [String] The rule definition.
      def rule
        value == "" ? STAR : "#{STAR}#{DOT}#{value}"
      end

      # dot-split rule value and returns all rule parts
      # in the order they appear in the value.
      #
      # @return [Array<String>]
      def parts
        @value.split(DOT)
      end

      # Decomposes the domain name according to rule properties.
      #
      # @param  [String, #to_s] name The domain name to decompose
      # @return [Array<String>] The array with [trd + sld, tld].
      def decompose(domain : String) : Tuple(String?, String?)
        value = @value
        return {nil, nil} unless domain.ends_with?(value)

        dbs = domain.size
        vbs = value.size
        index = dbs - vbs - 1
        return {nil, nil} if (index <= 0) && vbs > 0

        if (vbs == 0) || (domain[index] == DOT)
          if index2 = domain.rindex('.', index - 1)
            {domain[0, index2], domain[index2 + 1..-1]}
          else
            {nil, nil}
          end
        else
          {nil, nil}
        end
      end
    end

    # Exception represents an exception rule (e.g. !parliament.uk).
    struct Exception < Base
      # Initializes a new rule from the content.
      #
      # @param  content [String] the content of the rule
      # @param  private [Boolean]
      def self.build(content, _private = false)
        new(value: content.to_s[1..-1], _private: _private)
      end

      # Gets the original rule definition.
      #
      # @return [String] The rule definition.
      def rule
        BANG + value
      end

      # dot-split rule value and returns all rule parts
      # in the order they appear in the value.
      # The leftmost label is not considered a label.
      #
      # See http://publicsuffix.org/format/:
      # If the prevailing rule is a exception rule,
      # modify it by removing the leftmost label.
      #
      # @return [Array<String>]
      def parts
        @value.split(DOT)[1..-1]
      end

      @tail : String?

      def tail
        @tail ||= parts.join('.')
      end

      # Decomposes the domain name according to rule properties.
      #
      # @param  [String, #to_s] name The domain name to decompose
      # @return [Array<String>] The array with [trd + sld, tld].
      def decompose(domain : String) : Tuple(String?, String?)
        value = tail
        return {nil, nil} unless domain.ends_with?(value)

        dbs = domain.size
        vbs = value.size
        index = dbs - vbs - 1
        return {nil, nil} if index <= 0

        if domain[index] == DOT
          {domain[0, index], value}
        else
          {nil, nil}
        end
      end
    end

    # Takes the +name+ of the rule, detects the specific rule class
    # and creates a new instance of that class.
    # The +name+ becomes the rule +value+.
    #
    # @example Creates a Normal rule
    #   PublicSuffix::Rule.factory("ar")
    #   # => #<PublicSuffix::Rule::Normal>
    #
    # @example Creates a Wildcard rule
    #   PublicSuffix::Rule.factory("*.ar")
    #   # => #<PublicSuffix::Rule::Wildcard>
    #
    # @example Creates an Exception rule
    #   PublicSuffix::Rule.factory("!congresodelalengua3.ar")
    #   # => #<PublicSuffix::Rule::Exception>
    #
    # @param  [String] content The rule content.
    # @return [PublicSuffix::Rule::*] A rule instance.
    def self.factory(content : String, _private = false)
      raise ArgumentError.new("expected not empty content") if content.empty?

      case content[0]
      when STAR
        Wildcard.build(content, _private: _private)
      when BANG
        Exception.build(content, _private: _private)
      else
        Normal.build(content, _private: _private)
      end
    end

    # The default rule to use if no rule match.
    #
    # The default rule is "*". From https://publicsuffix.org/list/:
    #
    # > If no rules match, the prevailing rule is "*".
    #
    # @return [PublicSuffix::Rule::Wildcard] The default rule.
    def self.default
      DEFAULT
    end

    DEFAULT = Wildcard.new("", 2)
  end
end

# = Public Suffix
#
# Domain name parser based on the Public Suffix List.
#
# Copyright (c) 2009-2017 Simone Carletti <weppos@weppos.net>

module PublicSuffix
  # A {PublicSuffix::List} is a collection of one
  # or more {PublicSuffix::Rule}.
  #
  # Given a {PublicSuffix::List},
  # you can add or remove {PublicSuffix::Rule},
  # iterate all items in the list or search for the first rule
  # which matches a specific domain name.
  #
  #   # Create a new list
  #   list =  PublicSuffix::List.new
  #
  #   # Push two rules to the list
  #   list << PublicSuffix::Rule.factory("it")
  #   list << PublicSuffix::Rule.factory("com")
  #
  #   # Get the size of the list
  #   list.size
  #   # => 2
  #
  #   # Search for the rule matching given domain
  #   list.find("example.com")
  #   # => #<PublicSuffix::Rule::Normal>
  #   list.find("example.org")
  #   # => nil
  #
  # You can create as many {PublicSuffix::List} you want.
  # The {PublicSuffix::List.default} rule list is used
  # to tokenize and validate a domain.
  #
  class List
    DEFAULT_LIST_PATH = File.expand_path("../../publicsuffix-ruby/data/list.txt", __DIR__)

    @@default : List?

    # Gets the default rule list.
    #
    # Initializes a new {PublicSuffix::List} parsing the content
    # of {PublicSuffix::List.default_list_content}, if required.
    #
    # @return [PublicSuffix::List]
    def self.default
      @@default ||= PublicSuffix.generated_list
      # parse(File.read(DEFAULT_LIST_PATH))
    end

    # Sets the default rule list to +value+.
    #
    # @param [PublicSuffix::List] value
    #   The new rule list.
    #
    # @return [PublicSuffix::List]
    def self.default=(value)
      @@default = value
    end

    # Parse given +input+ treating the content as Public Suffix List.
    #
    # See http://publicsuffix.org/format/ for more details about input format.
    #
    # @param  string [#each_line] The list to parse.
    # @param  private_domains [Boolean] whether to ignore the private domains section.
    # @return [Array<PublicSuffix::Rule::*>]
    def self.parse(input, private_domains = true)
      comment_token = "//"
      private_token = "===BEGIN PRIVATE DOMAINS==="
      section = nil # 1 == ICANN, 2 == PRIVATE

      list = List.new
      input.each_line do |line|
        line = line.strip

        case
        when line.empty?
          # skip
        when line.includes?(private_token)
          break if !private_domains
          section = 2
        when line.starts_with?(comment_token)
          # skip
        else
          list.add(Rule.factory(line, _private: section == 2))
        end
      end

      list
    end

    # Initializes an empty {PublicSuffix::List}.
    #
    # @yield [self] Yields on self.
    # @yieldparam [PublicSuffix::List] self The newly created instance.
    def initialize
      @rules = {} of String => Rule::Base
    end

    # Adds the given object to the list and optionally refreshes the rule index.
    #
    # @param  rule [PublicSuffix::Rule::*] the rule to add to the list
    # @return [self]
    def add(rule : Rule::Base)
      @rules[rule.value] = rule
      self
    end

    def add(rule : String, _private = false)
      add(Rule.factory(rule, _private: _private))
    end

    # alias << add

    # Gets the number of rules in the list.
    #
    # @return [Integer]
    def size
      @rules.size
    end

    # Checks whether the list is empty.
    #
    # @return [Boolean]
    def empty?
      @rules.empty?
    end

    # Removes all rules.
    #
    # @return [self]
    def clear
      @rules.clear
      self
    end

    # Finds and returns the rule corresponding to the longest public suffix for the hostname.
    #
    # @param  name [#to_s] the hostname
    # @param  default [PublicSuffix::Rule::*] the default rule to return in case no rule matches
    # @return [PublicSuffix::Rule::*]
    def find(name, default = default_rule, **options)
      arr = filter(name, **options)

      rule = if arr.size > 0
               arr.reduce do |l, r|
                 return r if r.is_a?(Rule::Exception)
                 l.length > r.length ? l : r
               end
             else
               default
             end
    end

    # Selects all the rules matching given hostame.
    #
    # If `ignore_private` is set to true, the algorithm will skip the rules that are flagged as
    # private domain. Note that the rules will still be part of the loop.
    # If you frequently need to access lists ignoring the private domains,
    # you should create a list that doesn't include these domains setting the
    # `private_domains: false` option when calling {.parse}.
    #
    # Note that this method is currently private, as you should not rely on it. Instead,
    # the public interface is {#find}. The current internal algorithm allows to return all
    # matching rules, but different data structures may not be able to do it, and instead would
    # return only the match. For this reason, you should rely on {#find}.
    #
    # @param  name [#to_s] the hostname
    # @param  ignore_private [Boolean]
    # @return [Array<PublicSuffix::Rule::*>]
    def filter(name : String, ignore_private = false)
      parts = name.split(DOT).reverse!
      index = 0
      query = parts[index]
      rules = [] of Rule::Base

      loop do
        if (rule = @rules[query]?) && (ignore_private == false || rule._private == false)
          rules << rule
        end

        index += 1
        break if index >= parts.size
        query = parts[index] + DOT.to_s + query
      end

      rules
    end

    # Gets the default rule.
    #
    # @see PublicSuffix::Rule.default_rule
    #
    # @return [PublicSuffix::Rule::*]
    def default_rule
      PublicSuffix::Rule.default
    end

    getter :rules
  end
end

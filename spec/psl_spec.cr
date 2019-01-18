require "./spec_helper"

TESTS = begin
  res = [] of Tuple(String?, String?)

  File.read("./spec/tests.txt").split("\n").each do |line|
    line = line.strip
    next if line.empty?
    next if line.starts_with?("//")
    input, output = line.split(", ")

    if input[0] == '\''
      input = input[1..-2]
    else
      input = nil
    end

    if output[0] == '\''
      output = output[1..-2]
    else
      output = nil
    end

    res << {input, output}
  end

  res
end

describe PublicSuffix do
  context "psl" do
    TESTS.each do |input, output|
      next if input =~ /xn\-\-/

      it do
        domain = PublicSuffix.domain(input.to_s) rescue nil
        domain.should eq output
      end
    end
  end
end

require File.dirname(__FILE__) + "/../../test_helper"

class QueryParserTest < Test::Unit::TestCase

  def test_strings()
    parser = Ferret::QueryParser.new("xxx", :fields => ["f1", "f2", "f3"])
    pairs = [
      ['word', 'word'],
      ['field:word', 'field:word'],
      ['"word1 word2 word3"', '"word word word"'],
      ['"word1 2342 word3"', '"word word"'],
      ['field:"one two three"', 'field:"one two three"'],
      ['field:"one 222 three"', 'field:"one three"'],
      ['field:"one <> three"', 'field:"one <> three"'],
      ['field:"one <> three <>"', 'field:"one <> three"'],
      ['field:"one <> <> <> three <>"', 'field:"one <> <> <> three"'],
      ['field:"one <> <> <> three|four|five <>"', 'field:"one <> <> <> three|four|five"'],
      ['field:"one|two three|four|five six|seven"', 'field:"one|two three|four|five six|seven"'],
      ['[aaa bbb]', '[aaa bbb]'],
      ['{aaa bbb]', '{aaa bbb]'],
      ['field:[aaa bbb}', 'field:[aaa bbb}'],
      ['{aaa bbb}', '{aaa bbb}'],
      ['{aaa>', '{aaa>'],
      ['[aaa>', '[aaa>'],
      ['field:<aaa}', 'field:<aaa}'],
      ['<aaa]', '<aaa]'],
      ['>aaa', '{aaa>'],
      ['>=aaa', '[aaa>'],
      ['<aaa', '<aaa}'],
      ['field:<=aaa', 'field:<aaa]'],
      ['REQ one REQ two', '+one +two'],
      ['REQ one two', '+one two'],
      ['one REQ two', 'one +two'],
      ['+one +two', '+one +two'],
      ['+one two', '+one two'],
      ['one +two', 'one +two'],
      ['-one -two', '-one -two'],
      ['-one two', '-one two'],
      ['one -two', 'one -two'],
      ['!one !two', '-one -two'],
      ['!one two', '-one two'],
      ['one !two', 'one -two'],
      ['NOT one NOT two', '-one -two'],
      ['NOT one two', '-one two'],
      ['one NOT two', 'one -two'],
      ['one two', 'one two'],
      ['one OR two', 'one two'],
      ['one AND two', '+one +two'],
      ['one two AND three', 'one two +three'],
      ['one two OR three', 'one two three'],
      ['one (two AND three)', 'one (+two +three)'],
      ['one AND (two OR three)', '+one +(two three)'],
      ['field:(one AND (two OR three))', '+field:one +(field:two field:three)'],
      ['one AND (two OR [aaa vvv})', '+one +(two [aaa vvv})'],
      ['one AND (one:two OR two:three) AND four', '+one +(one:two two:three) +four'],
      ['one^1.23', 'one^1.23'],
      ['(one AND two)^100.23', '(+one +two)^100.23'],
      ['field:(one AND two)^100.23', '(+field:one +field:two)^100.23'],
      ['field:(one AND [aaa bbb]^23.3)^100.23', '(+field:one +field:[aaa bbb]^23.3)^100.23'],
      ['(REQ field:"one two three")^23', 'field:"one two three"^23.0'],
      ['asdf~0.2', 'asdf~0.2'],
      ['field:asdf~0.2', 'field:asdf~0.2'],
      ['asdf~0.2^100.0', 'asdf~0.2^100.0'],
      ['field:asdf~0.2^0.1', 'field:asdf~0.2^0.1'],
      ['field:"asdf <> asdf|asdf"~4', 'field:"asdf <> asdf|asdf"~4'],
      ['"one two three four five"~5', '"one two three four five"~5'],
      ['ab?de', 'ab?de'],
      ['ab*de', 'ab*de'],
      ['asdf?*?asd*dsf?asfd*asdf?', 'asdf?*?asd*dsf?asfd*asdf?'],
      ['field:a* AND field:(b*)', '+field:a* +field:b*'],
      ['field:abc~ AND field:(b*)', '+field:abc~0.5 +field:b*'],
      ['asdf?*?asd*dsf?asfd*asdf?^20.0', 'asdf?*?asd*dsf?asfd*asdf?^20.0'],

      ['*:xxx', 'f1:xxx f2:xxx f3:xxx'],
      ['f1|f2:xxx', 'f1:xxx f2:xxx'],

      ['*:asd~0.2', 'f1:asd~0.2 f2:asd~0.2 f3:asd~0.2'],
      ['f1|f2:asd~0.2', 'f1:asd~0.2 f2:asd~0.2'],

      ['*:a?d*^20.0', '(f1:a?d* f2:a?d* f3:a?d*)^20.0'],
      ['f1|f2:a?d*^20.0', '(f1:a?d* f2:a?d*)^20.0'],

      ['*:"asdf <> xxx|yyy"', 'f1:"asdf <> xxx|yyy" f2:"asdf <> xxx|yyy" f3:"asdf <> xxx|yyy"'],
      ['f1|f2:"asdf <> xxx|yyy"', 'f1:"asdf <> xxx|yyy" f2:"asdf <> xxx|yyy"'],

      ['*:[bbb xxx]', 'f1:[bbb xxx] f2:[bbb xxx] f3:[bbb xxx]'],
      ['f1|f2:[bbb xxx]', 'f1:[bbb xxx] f2:[bbb xxx]'],

      ['*:(xxx AND bbb)', '+(f1:xxx f2:xxx f3:xxx) +(f1:bbb f2:bbb f3:bbb)'],
      ['f1|f2:(xxx AND bbb)', '+(f1:xxx f2:xxx) +(f1:bbb f2:bbb)'],
      ['asdf?*?asd*dsf?asfd*asdf?^20.0', 'asdf?*?asd*dsf?asfd*asdf?^20.0'],
      ['"onewordphrase"', 'onewordphrase']
    ]
      
    pairs.each do |pair|
      assert_equal(pair[1], parser.parse(pair[0]).to_s(parser.default_field))
    end
  end

  def test_qp_with_standard_analyzer()
    parser = Ferret::QueryParser.new("xxx", :fields => ["f1", "f2", "f3"],
                                     :analyzer => Ferret::Analysis::StandardAnalyzer.new)
    pairs = [
    ['key:1234', 'key:1234'],
      ['key:(1234)', 'key:1234']
    ]
      
    pairs.each do |pair|
      assert_equal(pair[1], parser.parse(pair[0]).to_s(parser.default_field))
    end
  end
end
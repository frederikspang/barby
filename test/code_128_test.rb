require 'test_helper'
require 'barby/barcode/code_128'

describe Barby::Code128 do
  %w[CODEA CODEB CODEC FNC1 FNC2 FNC3 FNC4 SHIFT].each do |const|
    const_set const, Barby::Code128.const_get(const)
  end

  before do
    @data = 'ABC123'
    @code = Barby::Code128A.new(@data)
  end

  it 'should have the expected stop encoding (including termination bar 11)' do
    expect(@code.send(:stop_encoding)).must_equal '1100011101011'
  end

  it 'should find the right class for a character A, B or C' do
    expect(@code.send(:class_for, 'A')).must_equal Barby::Code128A
    expect(@code.send(:class_for, 'B')).must_equal Barby::Code128B
    expect(@code.send(:class_for, 'C')).must_equal Barby::Code128C
  end

  it 'should find the right change code for a class' do
    expect(@code.send(:change_code_for_class, Barby::Code128A)).must_equal Barby::Code128::CODEA
    expect(@code.send(:change_code_for_class, Barby::Code128B)).must_equal Barby::Code128::CODEB
    expect(@code.send(:change_code_for_class, Barby::Code128C)).must_equal Barby::Code128::CODEC
  end

  it 'should not allow empty data' do
    expect { Barby::Code128B.new('') }.must_raise(ArgumentError)
  end

  describe 'single encoding' do
    before do
      @data = 'ABC123'
      @code = Barby::Code128A.new(@data)
    end

    it 'should have the same data as when initialized' do
      expect(@code.data).must_equal @data
    end

    it 'should be able to change its data' do
      @code.data = '123ABC'
      expect(@code.data).must_equal '123ABC'
      expect(@code.data).wont_equal @data
    end

    it 'should not have an extra' do
      assert @code.extra.nil?
    end

    it 'should have empty extra encoding' do
      expect(@code.extra_encoding).must_equal ''
    end

    it 'should have the correct checksum' do
      expect(@code.checksum).must_equal 66
    end

    it 'should return all data for to_s' do
      expect(@code.to_s).must_equal @data
    end
  end

  describe 'multiple encodings' do
    before do
      @data = binary_encode("ABC123\306def\3074567")
      @code = Barby::Code128A.new(@data)
    end

    it 'should be able to return full_data which includes the entire extra chain excluding charset change characters' do
      expect(@code.full_data).must_equal 'ABC123def4567'
    end

    it 'should be able to return full_data_with_change_codes which includes the entire extra chain including charset change characters' do
      expect(@code.full_data_with_change_codes).must_equal @data
    end

    it 'should not matter if extras were added separately' do
      code = Barby::Code128B.new('ABC')
      code.extra = binary_encode("\3071234")
      expect(code.full_data).must_equal 'ABC1234'
      expect(code.full_data_with_change_codes).must_equal binary_encode("ABC\3071234")
      code.extra.extra = binary_encode("\306abc")
      expect(code.full_data).must_equal 'ABC1234abc'
      expect(code.full_data_with_change_codes).must_equal binary_encode("ABC\3071234\306abc")
      code.extra.extra.data = binary_encode("abc\305DEF")
      expect(code.full_data).must_equal 'ABC1234abcDEF'
      expect(code.full_data_with_change_codes).must_equal binary_encode("ABC\3071234\306abc\305DEF")
      expect(code.extra.extra.full_data).must_equal 'abcDEF'
      expect(code.extra.extra.full_data_with_change_codes).must_equal binary_encode("abc\305DEF")
      expect(code.extra.full_data).must_equal '1234abcDEF'
      expect(code.extra.full_data_with_change_codes).must_equal binary_encode("1234\306abc\305DEF")
    end

    it 'should have a Code B extra' do
      expect(@code.extra).must_be_instance_of(Barby::Code128B)
    end

    it 'should have a valid extra' do
      assert @code.extra.valid?
    end

    it 'the extra should also have an extra of type C' do
      expect(@code.extra.extra).must_be_instance_of(Barby::Code128C)
    end

    it "the extra's extra should be valid" do
      assert @code.extra.extra.valid?
    end

    it 'should not have more than two extras' do
      assert @code.extra.extra.extra.nil?
    end

    it 'should split extra data from string on data assignment' do
      @code.data = binary_encode("123\306abc")
      expect(@code.data).must_equal '123'
      expect(@code.extra).must_be_instance_of(Barby::Code128B)
      expect(@code.extra.data).must_equal 'abc'
    end

    it 'should be be able to change its extra' do
      @code.extra = binary_encode("\3071234")
      expect(@code.extra).must_be_instance_of(Barby::Code128C)
      expect(@code.extra.data).must_equal '1234'
    end

    it 'should split extra data from string on extra assignment' do
      @code.extra = binary_encode("\306123\3074567")
      expect(@code.extra).must_be_instance_of(Barby::Code128B)
      expect(@code.extra.data).must_equal '123'
      expect(@code.extra.extra).must_be_instance_of(Barby::Code128C)
      expect(@code.extra.extra.data).must_equal '4567'
    end

    it 'should not fail on newlines in extras' do
      code = Barby::Code128B.new(binary_encode("ABC\305\n"))
      expect(code.data).must_equal 'ABC'
      expect(code.extra).must_be_instance_of(Barby::Code128A)
      expect(code.extra.data).must_equal "\n"
      code.extra.extra = binary_encode("\305\n\n\n\n\n\nVALID")
      expect(code.extra.extra.data).must_equal "\n\n\n\n\n\nVALID"
    end

    it "should raise an exception when extra string doesn't start with the special code character" do
      expect { @code.extra = '123' }.must_raise ArgumentError
    end

    it 'should have the correct checksum' do
      expect(@code.checksum).must_equal 84
    end

    it 'should have the expected encoding' do
      # STARTA     A          B          C          1          2          3
      expect(@code.encoding).must_equal '11010000100101000110001000101100010001000110100111001101100111001011001011100' +
                                        # CODEB      d          e          f
                                        '10111101110100001001101011001000010110000100' +
                                        # CODEC      45         67
                                        '101110111101011101100010000101100' +
                                        # CHECK=84   STOP
                                        '100111101001100011101011'
    end

    it 'should return all data including extras, except change codes for to_s' do
      expect(@code.to_s).must_equal 'ABC123def4567'
    end
  end

  describe '128A' do
    before do
      @data = 'ABC123'
      @code = Barby::Code128A.new(@data)
    end

    it 'should be valid when given valid data' do
      assert @code.valid?
    end

    it 'should not be valid when given invalid data' do
      @code.data = 'abc123'
      refute @code.valid?
    end

    it 'should have the expected characters' do
      expect(@code.characters).must_equal %w[A B C 1 2 3]
    end

    it 'should have the expected start encoding' do
      expect(@code.start_encoding).must_equal '11010000100'
    end

    it 'should have the expected data encoding' do
      expect(@code.data_encoding).must_equal '101000110001000101100010001000110100111001101100111001011001011100'
    end

    it 'should have the expected encoding' do
      expect(@code.encoding).must_equal '11010000100101000110001000101100010001000110100111001101100111001011001011100100100001101100011101011'
    end

    it 'should have the expected checksum encoding' do
      expect(@code.checksum_encoding).must_equal '10010000110'
    end
  end

  describe '128B' do
    before do
      @data = 'abc123'
      @code = Barby::Code128B.new(@data)
    end

    it 'should be valid when given valid data' do
      assert @code.valid?
    end

    it 'should not be valid when given invalid data' do
      @code.data = binary_encode('abc£123')
      refute @code.valid?
    end

    it 'should have the expected characters' do
      expect(@code.characters).must_equal %w[a b c 1 2 3]
    end

    it 'should have the expected start encoding' do
      expect(@code.start_encoding).must_equal '11010010000'
    end

    it 'should have the expected data encoding' do
      expect(@code.data_encoding).must_equal '100101100001001000011010000101100100111001101100111001011001011100'
    end

    it 'should have the expected encoding' do
      expect(@code.encoding).must_equal '11010010000100101100001001000011010000101100100111001101100111001011001011100110111011101100011101011'
    end

    it 'should have the expected checksum encoding' do
      expect(@code.checksum_encoding).must_equal '11011101110'
    end
  end

  describe '128C' do
    before do
      @data = '123456'
      @code = Barby::Code128C.new(@data)
    end

    it 'should be valid when given valid data' do
      assert @code.valid?
    end

    it 'should not be valid when given invalid data' do
      @code.data = '123'
      refute @code.valid?
      @code.data = 'abc'
      refute @code.valid?
    end

    it 'should have the expected characters' do
      expect(@code.characters).must_equal %w[12 34 56]
    end

    it 'should have the expected start encoding' do
      expect(@code.start_encoding).must_equal '11010011100'
    end

    it 'should have the expected data encoding' do
      expect(@code.data_encoding).must_equal '101100111001000101100011100010110'
    end

    it 'should have the expected encoding' do
      expect(@code.encoding).must_equal '11010011100101100111001000101100011100010110100011011101100011101011'
    end

    it 'should have the expected checksum encoding' do
      expect(@code.checksum_encoding).must_equal '10001101110'
    end
  end

  describe 'Function characters' do
    it 'should retain the special symbols in the data accessor' do
      expect(Barby::Code128A.new(binary_encode("\301ABC\301DEF")).data).must_equal binary_encode("\301ABC\301DEF")
      expect(Barby::Code128B.new(binary_encode("\301ABC\302DEF")).data).must_equal binary_encode("\301ABC\302DEF")
      expect(Barby::Code128C.new(binary_encode("\301123456")).data).must_equal binary_encode("\301123456")
      expect(Barby::Code128C.new(binary_encode("12\30134\30156")).data).must_equal binary_encode("12\30134\30156")
    end

    it 'should keep the special symbols as characters' do
      expect(Barby::Code128A.new(binary_encode("\301ABC\301DEF")).characters).must_equal binary_encode_array(["\xC1", 'A', 'B', 'C', "\xC1", 'D', 'E', 'F'])
      expect(Barby::Code128B.new(binary_encode("\301ABC\302DEF")).characters).must_equal binary_encode_array(["\xC1", 'A', 'B', 'C', "\xC2", 'D', 'E', 'F'])
      expect(Barby::Code128C.new(binary_encode("\301123456")).characters).must_equal binary_encode_array(["\xC1", '12', '34', '56'])
      expect(Barby::Code128C.new(binary_encode("12\30134\30156")).characters).must_equal binary_encode_array(['12', "\xC1", '34', "\xC1", '56'])
    end

    it 'should not allow FNC > 1 for Code C' do
      expect { Barby::Code128C.new("12\302") }.must_raise ArgumentError
      expect { Barby::Code128C.new("\30312") }.must_raise ArgumentError
      expect { Barby::Code128C.new("12\304") }.must_raise ArgumentError
    end

    it 'should be included in the encoding' do
      a = Barby::Code128A.new(binary_encode("\301AB"))
      expect(a.data_encoding).must_equal '111101011101010001100010001011000'
      expect(a.encoding).must_equal '11010000100111101011101010001100010001011000101000011001100011101011'
    end
  end

  describe 'Code128 with type' do
    it 'should raise an exception when given a non-existent type' do
      expect { Barby::Code128.new('abc', 'F') }.must_raise(ArgumentError)
    end

    it 'should not fail on frozen type' do
      Barby::Code128.new('123456', 'C'.freeze) # not failing
      Barby::Code128.new('123456', 'c'.freeze) # not failing even when upcasing
    end

    it 'should give the right encoding for type A' do
      code = Barby::Code128.new('ABC123', 'A')
      expect(code.encoding).must_equal '11010000100101000110001000101100010001000110100111001101100111001011001011100100100001101100011101011'
    end

    it 'should give the right encoding for type B' do
      code = Barby::Code128.new('abc123', 'B')
      expect(code.encoding).must_equal '11010010000100101100001001000011010000101100100111001101100111001011001011100110111011101100011101011'
    end

    it 'should give the right encoding for type B' do
      code = Barby::Code128.new('123456', 'C')
      expect(code.encoding).must_equal '11010011100101100111001000101100011100010110100011011101100011101011'
    end
  end

  describe 'Code128 automatic charset' do
    #   5.4.7.7. Use of Start, Code Set, and Shift Characters to Minimize Symbol Length (Informative)
    #
    #   The same data may be represented by different GS1-128 barcodes through the use of different combinations of Start, code set, and shift characters.
    #
    #   The following rules should normally be implemented in printer control software to minimise the number of symbol characters needed to represent a given data string (and, therefore, reduce the overall symbol length).
    #
    #   * Determine the Start Character:
    #     - If the data consists of two digits, use Start Character C.
    #     - If the data begins with four or more numeric data characters, use Start Character C.
    #     - If an ASCII symbology element (e.g., NUL) occurs in the data before any lowercase character, use Start Character A.
    #     - Otherwise, use Start Character B.
    #   * If Start Character C is used and the data begins with an odd number of numeric data characters, insert a code set A or code set B character before the last digit, following rules 1c and 1d to determine between code sets A and B.
    #   * If four or more numeric data characters occur together when in code sets A or B and:
    #     - If there is an even number of numeric data characters, then insert a code set C character before the first numeric digit to change to code set C.
    #     - If there is an odd number of numeric data characters, then insert a code set C character immediately after the first numeric digit to change to code set C.
    #   * When in code set B and an ASCII symbology element occurs in the data:
    #     - If following that character, a lowercase character occurs in the data before the occurrence of another symbology element, then insert a shift character before the symbology element.
    #     - Otherwise, insert a code set A character before the symbology element to change to code set A.
    #   * When in code set A and a lowercase character occurs in the data:
    #     - If following that character, a symbology element occurs in the data before the occurrence of another lowercase character, then insert a shift character before the lowercase character.
    #     - Otherwise, insert a code set B character before the lowercase character to change to code set B.
    #     When in code set C and a non-numeric character occurs in the data, insert a code set A or code set B character before that character, and follow rules 1c and 1d to determine between code sets A and B.
    #
    #   Note: In these rules, the term “lowercase” is used for convenience to mean any code set B character with Code 128 Symbol character values 64 to 95 (ASCII values 96 to 127) (e.g., all lowercase alphanumeric characters plus `{|}~DEL). The term “symbology element” means any code set A character with Code 128 Symbol character values 64 to 95 (ASCII values 00 to 31).
    #   Note 2: If the Function 1 Symbol Character (FNC1) occurs in the first position following the Start Character, or in an odd-numbered position in a numeric field, it should be treated as two digits for the purpose of determining the appropriate code set.
    it 'should minimize symbol length according to GS1-128 guidelines' do
      # Determine the Start Character.
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10"
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}101234")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}101234"
      expect(Barby::Code128.apply_shortest_encoding_for_data("10\001LOT")).must_equal "#{Barby::Code128::CODEA}10\001LOT"
      expect(Barby::Code128.apply_shortest_encoding_for_data('lot1')).must_equal "#{Barby::Code128::CODEB}lot1"

      # Switching to codeset B from codeset C
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}101")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEB}1"
      # Switching to codeset A from codeset C
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10\001a")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEA}\001#{Barby::Code128::CODEB}a"

      # Switching to codeset C from codeset A
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10\001LOT1234")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEA}\001LOT#{Barby::Code128::CODEC}1234"
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10\001LOT12345")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEA}\001LOT1#{Barby::Code128::CODEC}2345"

      # Switching to codeset C from codeset B
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10LOT1234")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEB}LOT#{Barby::Code128::CODEC}1234"
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10LOT12345")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEB}LOT1#{Barby::Code128::CODEC}2345"

      # Switching to codeset A from codeset B
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10lot\001a")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEB}lot#{Barby::Code128::SHIFT}\001a"
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10lot\001\001")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEB}lot#{Barby::Code128::CODEA}\001\001"

      # Switching to codeset B from codeset A
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10\001l\001")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEA}\001#{Barby::Code128::SHIFT}l\001"
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10\001ll")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEA}\001#{Barby::Code128::CODEB}ll"

      # testing "Note 2" from the GS1 specification
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10LOT#{Barby::Code128::FNC1}0101")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEB}LOT#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}0101"
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10LOT#{Barby::Code128::FNC1}01010")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEB}LOT#{Barby::Code128::FNC1}0#{Barby::Code128::CODEC}1010"
      expect(Barby::Code128.apply_shortest_encoding_for_data("#{Barby::Code128::FNC1}10LOT01#{Barby::Code128::FNC1}0101")).must_equal "#{Barby::Code128::CODEC}#{Barby::Code128::FNC1}10#{Barby::Code128::CODEB}LOT#{Barby::Code128::CODEC}01#{Barby::Code128::FNC1}0101"
    end

    it 'should know how to extract CODEC segments properly from a data string' do
      expect(Barby::Code128.send(:extract_codec,
                                 "1234abcd5678\r\n\r\n")).must_equal ['1234', 'abcd', '5678', "\r\n\r\n"]
      expect(Barby::Code128.send(:extract_codec, '12345abc6')).must_equal %w[1234 5abc6]
      expect(Barby::Code128.send(:extract_codec, 'abcdef')).must_equal ['abcdef']
      expect(Barby::Code128.send(:extract_codec, '123abcdef45678')).must_equal %w[123abcdef4 5678]
      expect(Barby::Code128.send(:extract_codec, 'abcd12345')).must_equal %w[abcd1 2345]
      expect(Barby::Code128.send(:extract_codec, 'abcd12345efg')).must_equal %w[abcd1 2345 efg]
      expect(Barby::Code128.send(:extract_codec, '12345')).must_equal %w[1234 5]
      expect(Barby::Code128.send(:extract_codec, '12345abc')).must_equal %w[1234 5abc]
      expect(Barby::Code128.send(:extract_codec, 'abcdef1234567')).must_equal %w[abcdef1 234567]
    end

    it 'should know how to most efficiently apply different encodings to a data string' do
      expect(Barby::Code128.apply_shortest_encoding_for_data('123456')).must_equal "#{Barby::Code128::CODEC}123456"
      expect(Barby::Code128.apply_shortest_encoding_for_data('abcdef')).must_equal "#{Barby::Code128::CODEB}abcdef"
      expect(Barby::Code128.apply_shortest_encoding_for_data('ABCDEF')).must_equal "#{Barby::Code128::CODEB}ABCDEF"
      expect(Barby::Code128.apply_shortest_encoding_for_data("\n\t\r")).must_equal "#{Barby::Code128::CODEA}\n\t\r"
      expect(Barby::Code128.apply_shortest_encoding_for_data('123456abcdef')).must_equal "#{Barby::Code128::CODEC}123456#{Barby::Code128::CODEB}abcdef"
      expect(Barby::Code128.apply_shortest_encoding_for_data('abcdef123456')).must_equal "#{Barby::Code128::CODEB}abcdef#{Barby::Code128::CODEC}123456"
      expect(Barby::Code128.apply_shortest_encoding_for_data('1234567')).must_equal "#{Barby::Code128::CODEC}123456#{Barby::Code128::CODEB}7"
      expect(Barby::Code128.apply_shortest_encoding_for_data('123b456')).must_equal "#{Barby::Code128::CODEB}123b456"
      expect(Barby::Code128.apply_shortest_encoding_for_data('abc123def45678gh')).must_equal "#{Barby::Code128::CODEB}abc123def4#{Barby::Code128::CODEC}5678#{Barby::Code128::CODEB}gh"
      expect(Barby::Code128.apply_shortest_encoding_for_data("12345AB\nEEasdgr12EE\r\n")).must_equal "#{Barby::Code128::CODEC}1234#{Barby::Code128::CODEA}5AB\nEE#{Barby::Code128::CODEB}asdgr12EE#{Barby::Code128::CODEA}\r\n"
      expect(Barby::Code128.apply_shortest_encoding_for_data("123456QWERTY\r\n\tAAbbcc12XX34567")).must_equal "#{Barby::Code128::CODEC}123456#{Barby::Code128::CODEA}QWERTY\r\n\tAA#{Barby::Code128::CODEB}bbcc12XX3#{Barby::Code128::CODEC}4567"

      expect(Barby::Code128.apply_shortest_encoding_for_data("ABCdef\rGHIjkl")).must_equal "#{Barby::Code128::CODEB}ABCdef#{Barby::Code128::SHIFT}\rGHIjkl"
      expect(Barby::Code128.apply_shortest_encoding_for_data("ABC\rb\nDEF12gHI3456")).must_equal "#{Barby::Code128::CODEA}ABC\r#{Barby::Code128::SHIFT}b\nDEF12#{Barby::Code128::CODEB}gHI#{Barby::Code128::CODEC}3456"
      expect(Barby::Code128.apply_shortest_encoding_for_data("ABCdef\rGHIjkl\tMNop\nqRs")).must_equal "#{Barby::Code128::CODEB}ABCdef#{Barby::Code128::SHIFT}\rGHIjkl#{Barby::Code128::SHIFT}\tMNop#{Barby::Code128::SHIFT}\nqRs"
    end

    it 'should apply automatic charset when no charset is given' do
      b = Barby::Code128.new("123456QWERTY\r\n\tAAbbcc12XX34567")
      expect(b.type).must_equal 'C'
      expect(b.full_data_with_change_codes).must_equal "123456#{Barby::Code128::CODEA}QWERTY\r\n\tAA#{Barby::Code128::CODEB}bbcc12XX3#{Barby::Code128::CODEC}4567"
    end
  end

  private

  def binary_encode_array(datas)
    datas.each { |data| binary_encode(data) }
  end

  def binary_encode(data)
    data.force_encoding('BINARY')
  end
end

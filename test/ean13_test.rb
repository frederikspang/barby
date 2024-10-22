require 'test_helper'
require 'barby/barcode/ean_13'

describe Barby::EAN13 do
  describe 'validations' do
    before do
      @valid = Barby::EAN13.new('123456789012')
    end

    it 'should be valid with 12 digits' do
      assert @valid.valid?
    end

    it 'should not be valid with non-digit characters' do
      @valid.data = "The shit apple doesn't fall far from the shit tree"
      refute @valid.valid?
    end

    it 'should not be valid with less than 12 digits' do
      @valid.data = '12345678901'
      refute @valid.valid?
    end

    it 'should not be valid with more than 12 digits' do
      @valid.data = '1234567890123'
      refute @valid.valid?
    end

    it 'should raise an exception when data is invalid' do
      expect { Barby::EAN13.new('123') }.must_raise(ArgumentError)
    end
  end

  describe 'data' do
    before do
      @data = '007567816412'
      @code = Barby::EAN13.new(@data)
    end

    it 'should have the same data as was passed to it' do
      expect(@code.data).must_equal @data
    end

    it 'should have the expected characters' do
      expect(@code.characters).must_equal @data.chars
    end

    it 'should have the expected numbers' do
      expect(@code.numbers).must_equal(@data.chars.map { |s| s.to_i })
    end

    it 'should have the expected odd_and_even_numbers' do
      expect(@code.odd_and_even_numbers).must_equal [[2, 4, 1, 7, 5, 0], [1, 6, 8, 6, 7, 0]]
    end

    it 'should have the expected left_numbers' do
      # 0=second number in number system code
      expect(@code.left_numbers).must_equal [0, 7, 5, 6, 7, 8]
    end

    it 'should have the expected right_numbers' do
      expect(@code.right_numbers).must_equal [1, 6, 4, 1, 2, 5] # 5=checksum
    end

    it 'should have the expected numbers_with_checksum' do
      expect(@code.numbers_with_checksum).must_equal @data.chars.map { |s| s.to_i } + [5]
    end

    it 'should have the expected data_with_checksum' do
      expect(@code.data_with_checksum).must_equal @data + '5'
    end

    it 'should return all digits and the checksum on to_s' do
      expect(@code.to_s).must_equal '0075678164125'
    end
  end

  describe 'checksum' do
    before do
      @code = Barby::EAN13.new('007567816412')
    end

    it 'should have the expected weighted_sum' do
      expect(@code.weighted_sum).must_equal 85
      @code.data = '007567816413'
      expect(@code.weighted_sum).must_equal 88
    end

    it 'should have the correct checksum' do
      expect(@code.checksum).must_equal 5
      @code.data = '007567816413'
      expect(@code.checksum).must_equal 2
    end

    it 'should have the correct checksum_encoding' do
      expect(@code.checksum_encoding).must_equal '1001110'
    end
  end

  describe 'encoding' do
    before do
      @code = Barby::EAN13.new('750103131130')
    end

    it 'should have the expected checksum' do
      expect(@code.checksum).must_equal 9
    end

    it 'should have the expected checksum_encoding' do
      expect(@code.checksum_encoding).must_equal '1110100'
    end

    it 'should have the expected left_parity_map' do
      expect(@code.left_parity_map).must_equal %i[odd even odd even odd even]
    end

    it 'should have the expected left_encodings' do
      expect(@code.left_encodings).must_equal %w[0110001 0100111 0011001 0100111 0111101 0110011]
    end

    it 'should have the expected right_encodings' do
      expect(@code.right_encodings).must_equal %w[1000010 1100110 1100110 1000010 1110010 1110100]
    end

    it 'should have the expected left_encoding' do
      expect(@code.left_encoding).must_equal '011000101001110011001010011101111010110011'
    end

    it 'should have the expected right_encoding' do
      expect(@code.right_encoding).must_equal '100001011001101100110100001011100101110100'
    end

    it 'should have the expected encoding' do
      # Start   Left                                           Center    Right                                          Stop
      expect(@code.encoding).must_equal '101' + '011000101001110011001010011101111010110011' + '01010' + '100001011001101100110100001011100101110100' + '101'
    end
  end

  describe 'static data' do
    before :each do
      @code = Barby::EAN13.new('123456789012')
    end

    it 'should have the expected start_encoding' do
      expect(@code.start_encoding).must_equal '101'
    end

    it 'should have the expected stop_encoding' do
      expect(@code.stop_encoding).must_equal '101'
    end

    it 'should have the expected center_encoding' do
      expect(@code.center_encoding).must_equal '01010'
    end
  end
end

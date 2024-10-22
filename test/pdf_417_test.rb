if defined? JRUBY_VERSION

  require "test_helper"
  require "barby/barcode/pdf_417"

  class Pdf417Test < Barby::TestCase
    it "should produce a nice code" do
      enc = Pdf417.new("Ereshkigal").encoding
      enc.must_equal [
        "111111111101010100101111010110011110100111010110001110100011101101011100100001111111101000110100100",
        "111111111101010100101111010110000100100110100101110000101011111110101001111001111111101000110100100",
        "111111111101010100101101010111111000100100011100110011111010101100001111100001111111101000110100100",
        "111111111101010100101111101101111110110100010100011101111011010111110111111001111111101000110100100",
        "111111111101010100101101011110000010100110010101110010100011101101110001110001111111101000110100100",
        "111111111101010100101111101101110000110101101100000011110011110110111110111001111111101000110100100",
        "111111111101010100101101001111001111100110001101001100100010100111101110100001111111101000110100100",
        "111111111101010100101111110110010111100111100100101000110010101111111001111001111111101000110100100",
        "111111111101010100101010011101111100100101111110001110111011111101001110110001111111101000110100100",
        "111111111101010100101010001111011100100100111110111110111010100101100011100001111111101000110100100",
        "111111111101010100101101001111000010100110001101110000101011101100111001110001111111101000110100100",
        "111111111101010100101101000110011111100101111111011101100011111110100011100101111111101000110100100",
        "111111111101010100101010000101010000100100011100001100101010100100110000111001111111101000110100100",
        "111111111101010100101111010100100001100100010100111100101011110110001001100001111111101000110100100",
        "111111111101010100101111010100011110110110011111101001100010100100001001111101111111101000110100100"
      ]
      enc.length.must_equal 15
      enc[0].length.must_equal 99
    end

    it "should produce a 19x135 code with default aspect_ratio" do
      enc = Pdf417.new("qwertyuiopasdfghjklzxcvbnm" * 3).encoding
      enc.length.must_equal 19
      enc[0].length.must_equal 135
    end

    it "should produce a 29x117 code with 0.7 aspect_ratio" do
      enc = Pdf417.new("qwertyuiopasdfghjklzxcvbnm" * 3, aspect_ratio: 0.7).encoding
      enc.length.must_equal 29
      enc[0].length.must_equal 117
    end
  end

end

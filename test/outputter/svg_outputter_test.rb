require "test_helper"
require "barby/outputter/svg_outputter"

class SvgBarcode < Barby::Barcode
  attr_accessor :data, :two_d
  def initialize(data, two_d = false)
    self.data, self.two_d = data, two_d
  end

  def encoding
    data
  end

  def two_dimensional?
    two_d
  end

  def to_s
    data
  end
end

describe Barby::SvgOutputter do
  before do
    @barcode = SvgBarcode.new("10110011100011110000")
    @outputter = Barby::SvgOutputter.new(@barcode)
  end

  it "should register to_svg, bars_to_rects, and bars_to_path" do
    expect(Barby::Barcode.outputters).must_include :to_svg
    expect(Barby::Barcode.outputters).must_include :bars_to_rects
    expect(Barby::Barcode.outputters).must_include :bars_to_path
  end

  it "should return a string on to_svg" do
    expect(@barcode.to_svg).must_be_instance_of String
  end

  it "should return a string on bars_to_rects" do
    expect(@barcode.bars_to_rects).must_be_instance_of String
  end

  it "should return a string on bars_to_path" do
    expect(@barcode.bars_to_path).must_be_instance_of String
  end

  it "should produce one rect for each bar" do
    expect(@barcode.bars_to_rects.scan("<rect").size).must_equal @outputter.send(:boolean_groups).count { |bg| bg[0] }
  end

  it "should produce one path stroke for each bar module" do
    expect(@barcode.bars_to_path.scan(/(M\d+\s+\d+)\s*(V\d+)/).size).must_equal @outputter.send(:booleans).count { |bg| bg }
  end

  it "should return default values for attributes" do
    expect(@outputter.margin).must_be_instance_of Integer
  end

  it "should use defaults to populate higher level attributes" do
    expect(@outputter.xmargin).must_equal @outputter.margin
  end

  it "should return nil for overridden attributes" do
    @outputter.xmargin = 1
    expect(@outputter.margin).must_equal nil
  end

  it "should still use defaults for unspecified attributes" do
    @outputter.xmargin = 1
    expect(@outputter.ymargin).must_equal @outputter.send(:_margin)
  end

  it "should have a width equal to Xdim * barcode_string.length" do
    expect(@outputter.width).must_equal @outputter.barcode.encoding.length * @outputter.xdim
  end

  it "should have a full_width which is by default the sum of width + (margin*2)" do
    expect(@outputter.full_width).must_equal @outputter.width + (@outputter.margin * 2)
  end

  it "should have a full_width which is the sum of width + xmargin + ymargin" do
    expect(@outputter.full_width).must_equal @outputter.width + @outputter.xmargin + @outputter.ymargin
  end

  it "should use Barcode#to_s for title" do
    expect(@outputter.title).must_equal @barcode.data
    def @barcode.to_s
      "the eastern star"
    end
    expect(@outputter.title).must_equal "the eastern star"
  end
end

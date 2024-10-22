require 'barby/outputter'

module Barby
  # Renders the barcode to a simple SVG image using pure ruby
  #
  # Registers the to_svg, bars_to_path, and bars_to_rects method
  #
  # Bars can be rendered as a stroked path or as filled rectangles.  Path
  # generally yields smaller files, but this doesn't render cleanly in Firefox
  # 3 for odd xdims.  My guess is that the renderer tries to put half a pixel
  # on one side of the path and half on the other, leading to fuzzy dithering
  # instead of sharp, clean b&w.
  #
  # Therefore, default behavior is to use a path for even xdims, and
  # rectangles for odd.  This can be overridden by calling with explicit
  # :use => 'rects' or :use => 'path' options.
  class SvgOutputter < Outputter
    register :to_svg, :bars_to_rects, :bars_to_path

    attr_writer :title, :xdim, :ydim, :height, :rmargin, :lmargin, :tmargin, :bmargin, :xmargin, :ymargin, :margin,
                :foreground, :background

    def to_svg(opts = {})
      with_options opts do
        case opts[:use]
        when 'rects' then bars = bars_to_rects
        when 'path' then bars = bars_to_path
        else
          xdim_odd = xdim.odd?
          bars = xdim_odd ? bars_to_rects : bars_to_path
        end

        <<~"EOT"
          <?xml version="1.0" encoding="UTF-8"?>
          <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{svg_width(opts)}px" height="#{svg_height(opts)}px" viewBox="0 0 #{svg_width(opts)} #{svg_height(opts)}" version="1.1" preserveAspectRatio="none" >
          <title>#{escape title}</title>
          <g id="canvas" #{transform(opts)}>
          <rect x="0" y="0" width="#{full_width}px" height="#{full_height}px" fill="#{background}" />
          <g id="barcode" fill="#{foreground}">
          #{bars}
          </g></g>
          </svg>
        EOT
      end
    end

    def bars_to_rects(opts = {})
      rects = ''
      with_options opts do
        x = lmargin
        y = tmargin

        if barcode.two_dimensional?
          boolean_groups.each do |line|
            line.each do |bar, amount|
              bar_width = xdim * amount
              rects << %(<rect x="#{x}" y="#{y}" width="#{bar_width}px" height="#{ydim}px" />\n) if bar
              x += bar_width
            end
            y += ydim
            x = lmargin
          end

        else
          boolean_groups.each do |bar, amount|
            bar_width = xdim * amount
            rects << %(<rect x="#{x}" y="#{y}" width="#{bar_width}px" height="#{height}px" />\n) if bar
            x += bar_width
          end

        end
      end # with_options

      rects
    end

    def bars_to_path(opts = {})
      with_options opts do
        %(<path stroke="black" stroke-width="#{xdim}" d="#{bars_to_path_data(opts)}" />)
      end
    end

    def bars_to_path_data(opts = {})
      path_data = ''
      with_options opts do
        x = lmargin + (xdim / 2)
        y = tmargin

        if barcode.two_dimensional?
          booleans.each do |line|
            line.each do |bar|
              path_data << "M#{x} #{y}V #{y + ydim}" if bar
              x += xdim
            end
            y += ydim
            x = lmargin + (xdim / 2)
          end

        else
          booleans.each do |bar|
            path_data << "M#{x} #{y}V#{y + height}" if bar
            x += xdim
          end

        end
      end # with_options

      path_data
    end

    def title
      @title || barcode.to_s
    end

    def width
      length * xdim
    end

    def height
      barcode.two_dimensional? ? (ydim * encoding.length) : (@height || 100)
    end

    def full_width
      width + lmargin + rmargin
    end

    def full_height
      height + tmargin + bmargin
    end

    def xdim
      @xdim || 1
    end

    def ydim
      @ydim || xdim
    end

    def lmargin
      @lmargin || _xmargin
    end

    def rmargin
      @rmargin || _xmargin
    end

    def tmargin
      @tmargin || _ymargin
    end

    def bmargin
      @bmargin || _ymargin
    end

    def xmargin
      return nil if @lmargin || @rmargin

      _margin
    end

    def ymargin
      return nil if @tmargin || @bmargin

      _margin
    end

    def margin
      return nil if @ymargin || @xmargin || @tmargin || @bmargin || @lmargin || @rmargin

      _margin
    end

    def length
      barcode.two_dimensional? ? encoding.first.length : encoding.length
    end

    def foreground
      @foreground || '#000'
    end

    def background
      @background || '#fff'
    end

    def svg_width(opts = {})
      opts[:rot] ? full_height : full_width
    end

    def svg_height(opts = {})
      opts[:rot] ? full_width : full_height
    end

    def transform(opts = {})
      opts[:rot] ? %|transform="rotate(-90) translate(-#{full_width}, 0)"| : nil
    end

    private

    def _xmargin
      @xmargin || _margin
    end

    def _ymargin
      @ymargin || _margin
    end

    def _margin
      @margin || 10
    end

    # Escape XML special characters <, & and >
    def escape(str)
      str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    end
  end
end

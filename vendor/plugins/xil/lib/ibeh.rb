class ::Numeric
  def mm
    self*72/25.4
  end
end

module Ibeh

  def self.document(writer, view, &block)
    doc = Document.new(writer)
    view.instance_values.each do |k,v|
      doc.instance_variable_set("@"+k.to_s, v)
    end
    doc.call(doc, block)
    doc.writer
  end

  # Default xil element
  class Element
    attr_reader :writer

    def initialize(writer)
      @writer = writer
    end

    def call(element, block=nil)
      puts self.class.to_s+' > '+element.class.to_s
      if self!=element
        self.instance_values.each do |k,v|
          element.instance_variable_set("@"+k, v) unless element.instance_variable_defined? "@"+k
        end
      end
      if block
        block.arity < 1 ? element.instance_eval(&block) : block[element]
      end
    end
  end



  # Represents a <document>
  class Document < Element

    def page(format=:a4, options={}, &block)
      page = Page.new(@writer, format, options)
      call(page, block)
    end
  end




  # Represents a <page>
  class Page < Element
    FORMATS = {
      :a1=>[594.mm, 420.mm],
      :a2=>[420.mm, 594.mm],
      :a3=>[297.mm, 420.mm],
      :a4=>[210.mm, 297.mm],
      :a5=>[148.mm, 210.mm],
      :a6=>[105.mm, 148.mm]      
    }

    attr_reader :y, :env, :margin

    def initialize(writer, format, options)
      super writer
      @options = options
      format = FORMATS[format.to_s.lower.gsub(/[^\w]/,'').to_sym] unless format.is_a? Array
      format[0], format[1] = format[1], format[0] if @options[:orientation] == :landscape
      @format = format
      @margin = @options[:margin]||[]
      @margin[0] ||= 0
      @margin[1] ||= @margin[0]
      @margin[2] ||= @margin[0]
      @margin[3] ||= @margin[1]
      @env = {}
      variable(:font_size, 12)
      variable(:font_name, "Helvetica")
      page_break
    end
    
    def debug?
      @options[:debug]||false
    end

    def variable(name, value=nil)
      @env[name] = value unless value.nil?
      @env[name]
    end

    def part(height=nil, options={}, &block)
      height ||= @format[1]-@margin[0]-@margin[2]
      page_break if @y-height-@margin[2]<0
      part = Part.new(@writer, self, height)
      call(part, block)
      @y -= height
    end

    def page_break
      @writer.new_page(@format, @options[:rotate]||0)
      @y = @format[1]-@margin[0]
    end

    def width
      @format[0]
    end

    def height
      @format[1]
    end

  end







  # Represents a <part>
  class Part < Element

    def initialize(writer, page, height)
      super writer
      @page   = page
      @height = height
      @top    = @page.y
      if @page.debug?
        x1, x2 = @page.margin[3], @page.width-@page.margin[1]
        @writer.line [[x1, @top], [x2, @top-height]], :border=>{:color=>'#cdF', :width=>5}
        @writer.line [[x2, @top], [x1, @top-height]], :border=>{:color=>'#Fdc', :width=>5}
        @writer.line [[x1, @top], [x2, @top], [x2, @top-height], [x1, @top-height], [x1, @top]], :border=>{:color=>'#888', :width=>0}
      end
    end

    def set(left=0, top=0, env={}, &block)
      left += @page.margin[3]
      @writer.save_graphics_state
      set = Set.new(@writer, @page.env.dup.merge(env), left, @top-top)
      call(set, block)
      @writer.restore_graphics_state
    end

  end




  # Represents a <set>
  class Set < Element
    def initialize(writer, env, left, top)
      super writer
      @env  = env
      @left = left
      @top  = top
    end

    def variable(name, value=nil)
      @env[name] = value unless value.nil?
      @env[name]
    end

    def set(left=0, top=0, env={}, &block)
      @writer.save_graphics_state
      set = Set.new(@writer, @env.dup.merge(env), @left+left, @top-top)
      set.font
      call(set, block)
      @writer.restore_graphics_state
    end

    def font(name=nil, size=nil, color=nil)
      name = variable(:font_name, name)
      size = variable(:font_size, size)
      color = variable(:color, color)
      @writer.font name, :size=>size, :color=>color
    end

    def text(value, options={}, &block)
      left = options[:left]||0
      top  = options[:top]||0
      env = @env.dup
      font(options[:font], options[:size], options[:color])
      @writer.text value, :at=>[@left+left, @top-top-0.7*variable(:font_size)]
      @env = env
    end

    def image(file, width, height, options={}, &block)
      left = options[:left]||0
      top  = options[:top]||0      
      @writer.image file, @left+left, @top-top-height, width, height
    end

    def line(points, options={})
      @writer.line points.collect{|p| [@left+p[0], @top-p[1]]}, {:border=>options}
    end

    def width
      @page.width-@page.margin[1]-@page.margin[3]-@left
    end

  end

end

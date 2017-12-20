require 'gosu'
# --------------------------------------------------------------------------------------------------------------------------------
module Comparable
  def bound(range)
     return range.first if self < range.first
     return range.last if self > range.last
     self
  end
end
# --------------------------------------------------------------------------------------------------------------------------------
class Array
	def draw
		itself.each{|e| e.draw if e.respond_to?(:draw)}
	end
	def handle(id)
		itself.each{|e| e.handle(id) if e.respond_to?(:handle)}
	end
end
# --------------------------------------------------------------------------------------------------------------------------------
class Gosu::Window
	def backGround(content=0xff777777) # usable
		if content.respond_to?("is_a?") and content.is_a?(Gosu::Image)
			content.draw_rot(width/2,height/2,-1,0,0.5,0.5,width.to_f/content.width.to_f,height.to_f/content.height.to_f)
		else
			draw_rect(0,0,width,height,content.to_s.to_i,-1)
		end
	end
	def drawComponent(component,drawway)
		drawway.call(self,component)
	end
	def draw_rect(xo,yo,xf,yf,c=0xffffffff,z=0) # usable
		draw_quad(xo,yo,c,xf,yo,c,xf,yf,c,xo,yf,c,z)
	end
	def d_pointPos(p,raio,c=0xffffffff,z=0) # usable
		if( p != nil)
			draw_rect(p[0]-raio,p[1]-raio,p[0]+raio,p[1]+raio,c,z)
			draw_rect(p[0]-raio*0.5,p[1]-raio*1.5,p[0]+raio*0.5,p[1]+raio*0.5,c,z)
			draw_rect(p[0]-raio*0.5,p[1]-raio*0.5,p[0]+raio*0.5,p[1]+raio*1.5,c,z)
			draw_rect(p[0]-raio*1.5,p[1]-raio*0.5,p[0]+raio*0.5,p[1]+raio*0.5,c,z)
			draw_rect(p[0]-raio*0.5,p[1]-raio*0.5,p[0]+raio*1.5,p[1]+raio*0.5,c,z)
		end
	end
	def drawMouse(color=0xffffffff,size=1) # usable
		update_mouse
		d_pointPos([@mouse_x,@mouse_y],size*2,color,1<<32)
	end
	def update_mouse # usable
		@mouse_x=mouse_x.to_i.bound(0...width)
		@mouse_y=mouse_y.to_i.bound(0...height)
	end
	def button_up(id)
		@textinput.handle(id) if @textinput and @textinput.respond_to?(:handle)
		@inputhandler.handle(id) if @inputhandler and @inputhandler.respond_to?(:handle)
		key_up(id) if respond_to?(:key_up)
	end
	def button_down(id)
		if id==Gosu::KbLeftShift or id==Gosu::KbRightShift
			@textinput.handle_down(id) if @textinput and @textinput.respond_to?(:handle_down)
		end
		if id==Gosu::KbLeftShift or id==Gosu::KbRightShift
			@inputhandler.handle_down(id) if @inputhandler and @inputhandler.respond_to?(:handle_down)
		end
		if id==Gosu::MsLeft and @inputhandler
			@inputhandler.focus
		end
		key_down(id) if respond_to?(:key_down)
	end
end
# --------------------------------------------------------------------------------------------------------------------------------
class GosuTextInput
	INTIME=180

	attr_accessor :text
	def initialize(limit=-1)
		@limit=limit
		@text=""
		@lshifted,@rshifted=false,false
		@timer=Stopwatch.new()
	end
	def handle(id)
		changed=false
		if(id == Gosu::KbBackspace and @text.size>0 and @timer.elapsed_time >INTIME*3.0/4.0) then 
			@text.chop!
			changed=true
		end
		if(id == Gosu::KbSpace and @timer.elapsed_time >INTIME) then 
			append(" ") 
			changed=true
		end
		if id==Gosu::KbLeftShift
			@lshifted=false
			changed=true
		elsif id==Gosu::KbRightShift
			@rshifted=false
			changed=true
		end

		if (Gosu::Kb1..Gosu::Kb0).include?(id)
			sentence = sentenceFromCharRange(id,Gosu::Kb1..Gosu::Kb0,"0",-1)
			changed=true if addSentence(sentence)
		elsif (Gosu::KbA..Gosu::KbZ).include?(id)
			sentence = sentenceFromCharRange(id,Gosu::KbA..Gosu::KbZ,(shifted)?("A"):("a"),0)
			changed=true if addSentence(sentence)
		end
		if not changed and Gosu::button_id_to_char(id)
			changed=true if addSentence(Gosu::button_id_to_char(id))
		end

		if changed then @timer.restart end
	end
	def shifted
		@lshifted or @rshifted
	end
	def handle_down(id)
		if id==Gosu::KbLeftShift
			@lshifted=true
			@timer.restart
		elsif id==Gosu::KbRightShift
			@rshifted=true
			@timer.restart
		end
	end
	def sentenceFromCharRange(id,range,init_char,rotation=0)
		v=range.to_a.rotate(rotation)
		return (v.index(id)+init_char.ord).chr
	end
	def append(sentence)
		if @text.size<@limit or @limit<0 then @text.concat(sentence) end
	end
	def addSentence(sentence)
		if @timer.elapsed_time >INTIME or not @text.reverse.upcase.split("").first(3).include?(sentence.upcase)
			append (sentence) 
			return true
		end
		return false
	end
end
# --------------------------------------------------------------------------------------------------------------------------------
class GosuComponent
	attr_reader :x, :y, :width, :height
	def initialize(window,position,dimension)
		@window=window
		@x,@y=position[0],position[1]
		@width,@height=dimension[0],dimension[1]
	end
	def draw
		if respond_to?("drawway") then @window.drawComponent(self,drawway) end
	end
end
# --------------------------------------------------------------------------------------------------------------------------------
class GosuLabel < GosuComponent
	attr_reader :background, :text, :textImg, :fontcolor
	attr_writer :background, :fontcolor
	def initialize(window,position,dimension,text="",hasbackground=false,limit=1<<8,background=0xff555555,fontcolor=0xffffffff)
		super(window,position,dimension)
		@background,@fontcolor=(hasbackground)?(background):(nil),fontcolor
		@limit=limit
		@text=text
		@textImg=Gosu::Image.from_text(@window, @text.split("").first(@limit).join, Gosu.default_font_name, @height)
	end
	def hasBackGround
		return @background!=nil
	end
	def text=(v)
		@text=v
		@textImg=Gosu::Image.from_text(@window, @text.split("").first(@limit).join, Gosu.default_font_name, @height)
	end
	def drawway
		return lambda{ |window,label|
			if label.hasBackGround 
				window.draw_rect(label.x,label.y,label.x+[label.textImg.width+2,label.width].max,label.y+label.height,label.background) 
			end
			label.textImg.draw_rot(label.x+[label.textImg.width,label.width].max/2.0,label.y+label.height/2.0,1,0,0.5,0.5,1,1,label.fontcolor)
		}
	end
	def to_s
		@text.to_s
	end
	def to_c
		@text.to_c
	end
	def to_r
		@text.to_r
	end
	def to_i
		@text.to_i
	end
	def to_f
		@text.to_f
	end
end
# --------------------------------------------------------------------------------------------------------------------------------
class GosuButton < GosuComponent
	attr_reader :text, :textImg, :image, :background, :fontcolor
	def initialize(window,position,dimension,text,procedure,image=nil,background=0xff555555,fontcolor=0xffffffff)
		super(window,position,dimension)
		@procedure,@image,@background,@fontcolor=procedure,image,background,fontcolor
		@text=text
		@textImg=Gosu::Image.from_text(@window, (text)?(text):(""), Gosu.default_font_name, @height) # fontsize => height
	end
	def executeClick
		@procedure.call(@window) if @procedure!=nil
	end
	def handle(id)
		if(id==Gosu::MsLeft)
			mx,my=@window.mouse_x,@window.mouse_y
			if((mx-@x).between?(0,@width) and (my-@y).between?(0,@height))
				executeClick
			end
		end
	end
	alias button_up handle
	def drawway
		return lambda{ |window,button|
			if(button.image)
				button.image.draw(button.x,button.y,0)
			else
				window.draw_rect(button.x,button.y,button.x+[button.textImg.width+2,button.width].max,button.y+button.height,button.background)
			end
			button.textImg.draw_rot(button.x+[button.textImg.width,button.width].max/2.0,button.y+button.height/2.0,1,0,0.5,0.5,1,1,button.fontcolor)
		}
	end
end
# --------------------------------------------------------------------------------------------------------------------------------
class GosuInputHandler
	def initialize(window,textfields=[])
		@window=window
		@textfields=textfields
		@focused_field=nil
	end
	def addTextField(tf)
		@textfields.concat([tf].flatten)
	end
	def handle(id)
		if @focused_field
			if id==Gosu::KbLeftAlt 
				@focused_field=@textfields.at (@textfields.index(@focused_field)-1+@textfields.length).remainder(@textfields.length)
			elsif id==Gosu::KbTab
				@focused_field=@textfields.at (@textfields.index(@focused_field)+1).remainder(@textfields.length)
			else  
				@focused_field.textinput.handle(id)
			end
		end
	end
	def handle_down(id)
		if @focused_field  
			@focused_field.textinput.handle_down(id)
		end
	end
	def bufferize()
		(0...(1<<8)).to_a.each { |k|
			if Gosu::button_down?(k) and @focused_field then 
				@focused_field.textinput.handle(k)
				@focused_field.textinput.handle_down(k)
			end
		}
	end
	def update
		bufferize
		@textfields.each{|tf| tf.update}
	end
	def focus
		if not @textfields.empty? then
			@focused_field=[@textfields.select{|tf| tf.above([@window.mouse_x,@window.mouse_y])}].flatten.uniq[0]
		end
	end
	def draw
		@textfields.each{|tf| tf.draw}
	end
end
# --------------------------------------------------------------------------------------------------------------------------------
class GosuTextField < GosuLabel
	attr_accessor :textinput
	def initialize(window,position,dimension,text="",hasbackground=false,limit=-1,background=0xff555555,fontcolor=0xffffffff)
		super(window,position,dimension)
		@background,@fontcolor=(hasbackground)?(background):(nil),fontcolor
		@textinput=GosuTextInput.new(limit)
		@textinput.text=text
		update
	end
	def update
		@text=@textinput.text
		@textImg=Gosu::Image.from_text(@window, @text, Gosu.default_font_name, @height)
	end
	def text=(v)
		@textinput.text=v
		update
	end
	def above(mousepos)
		mx,my=mousepos[0],mousepos[1]
		return ((mx-@x).between?(0,[@textImg.width,@width].max) and (my-@y).between?(0,@height))
	end
end
# --------------------------------------------------------------------------------------------------------------------------------
class Stopwatch
  	def initialize()
    	@start = Time.now
  	end
  	def restart
    	@start = Time.now
  	end
  	def elapsed_time
	    now = Time.now
	    elapsed = now.to_ms - @start.to_ms
    	return elapsed
	end
end
# --------------------------------------------------------------------------------------------------------------------------------
class Time
  	def to_ms
    	(self.to_f * 1000.0).to_i
  	end
end



# --------------------------------------------------------------------------------------------------------------------------------
#GosuInputHandler: def initialize(window,textfields=[])
#GosuLabel:        def initialize(window,position,dimension,text="",hasbackground=false,limit=1<<8,background=0xff555555,fontcolor=0xffffffff)
#GosuButton:       def initialize(window,position,dimension,text,procedure,image=nil,background=0xff555555,fontcolor=0xffffffff)
#GosuTextField:    def initialize(window,position,dimension,text="",hasbackground=false,limit=-1,background=0xff555555,fontcolor=0xffffffff)
#GosuTextInput:    def initialize(limit=-1) @attr_accessor :text
#
#Gosu::Window
# 
# def backGround(content=0xff777777)
# def draw_rect(xo,yo,xf,yf,c=0xffffffff,z=0)
# def d_pointPos(p,raio,c=0xffffffff,z=0)
# def drawMouse(color=0xffffffff,size=1)
# def update_mouse    
# variables: @caption,@mouse_x,@mouse_y,@textinput,@inputhandler
#
# Substitution: button_up => key_up, button_down => key_down
#

require_relative 'GosuGUI'

class MasterMind < Gosu::Window
	def initialize(width,height,bool=false)
		super(width,height,bool)
		self.caption= "MasterMind Senha. - Adap. Hasbro"
		@color_hex = {red: 0xffff0000, orange: 0xffff7f00, yellow: 0xffffff00, green: 0xff00ff00, blue: 0xff0000ff, purple: 0xff7f00ff, pink: 0xffff7fff, grey: 0xff7f7f7f, black: 0xff000000}
		@colors = @color_hex.keys[0..-3]
		@buttons, @info_pins,@color_pins, = [], [], []
		bt_hght, sq_hght = 40, 60
		@colors.each_with_index do |color,idx|
			@buttons << GosuButton.new(self,[10+(width/12)*(idx%2),30+sq_hght*(idx/2)],[width/12-3,sq_hght-3],(idx+1).to_s.capitalize,lambda{|window| window.selected(color)},nil,@color_hex[color],0xff000000)
		end
		@buttons << GosuButton.new(self,[10,height-bt_hght*4],[width/6,bt_hght-3],"Submit",lambda{|window| window.submit},nil,0xffffffff,0xff000000)
		@buttons << GosuButton.new(self,[10,height-bt_hght*3],[width/6,bt_hght-3],"Clear",lambda{|window| window.clear_line},nil,0xffffffff,0xff000000)
		@buttons << GosuButton.new(self,[10,height-bt_hght*2],[width/6,bt_hght-3],"Restart",lambda{|window| window.reinit},nil,0xffffffff,0xff000000)
		@buttons << GosuButton.new(self,[10,height-bt_hght],[width/6,bt_hght-3],"Quit",lambda{|window| exit},nil,0xffffffff,0xff000000)
		(10*4).times do |i|
			x, y= i % 4, 9 - i / 4
			@color_pins << GosuLabel.new(self,[width*2/6+width*x/6,(height*0.05).to_i+(height*0.9/10).to_i*y],[width/6-1,(height*0.8/10).to_i-1],"",true,1<<8,0x0)
		end
		(10).times do |i|
			y = 9 - i
			@info_pins << GosuLabel.new(self,[width*1.2/6,(height*0.05).to_i+((height*0.9/40)+(height*0.9/10)*y).to_i],[width*0.8/6,(height*0.8/20).to_i-1],"",true,1<<8,0x0, 0xff000000)
		end
		@end_label = GosuLabel.new(self,[width/2-width/12,height/2-height/20],[width/6,height/10],"",true,1<<8,0x0,0x0)
		@drawables = [@buttons,@info_pins,@color_pins,@end_label]
		reinit
	end
	def reinit
		@color_pins.each{|cp| cp.background=0x0}
		@info_pins.each{|ip| ip.text=""}
		@guesses = []
		@password = randomPassword()
		clear_line()
		@state = :playing
		@end_label.background=0x0
		@end_label.text=""
	end
	def randomPassword
		pass = []
		while pass.size < 4
			pass << @colors.sample
			pass.uniq!
		end
		return pass
	end
	def button_up(id)
		@buttons.handle(id)
		submit() if id == Gosu::KbReturn
		clear_line() if id == Gosu::KbBackspace
		exit if id == Gosu::KbEscape
		if (Gosu::KB_1..Gosu::KB_7).include?(id)
			selected @colors[id-Gosu::KB_1]
		end
	end
	def draw
		backGround(@color_hex[:grey])
		@drawables.draw
		drawMouse(0xff000044,3)
	end
	def needs_cursor?
		false
	end
	def selected color
		if @state == :playing 
			guess = @passwordGuess.dup
			guess[@currentIdx]=color
			if guess == guess.uniq
				@passwordGuess = guess
				@color_pins[@currentIdx+4*@guesses.size].background = @color_hex[color]
				@currentIdx = (@currentIdx + 1) % 4
			end
		end
	end
	def clear_line 
		@black_pins, @white_pins = 0, 0
		@currentIdx=0
		@passwordGuess=[""]
		4.times{|i| @color_pins[i+4*@guesses.size].background = 0x0} if @state != :stopped
	end
	def give_answer
		@black_pins = @passwordGuess.count{|v| i = @passwordGuess.index(v); v == @password[i]}
		@white_pins = @passwordGuess.count{|v| @password.include?(v)} - @black_pins
		return "!#{@black_pins} ?#{@white_pins}"
	end
	def submit
		if @state == :playing and @passwordGuess.size == 4
			@info_pins[@guesses.size].text = give_answer()
			@guesses << @passwordGuess
			if (@black_pins==4)
				@state = :stopped 
				@end_label.background=@color_hex[:black]
				@end_label.fontcolor=@color_hex[:green]
				@end_label.text="WIN!"
			end
			if (@black_pins<4 and @guesses.size==10)
				@state = :stopped 
				@end_label.background=@color_hex[:black]
				@end_label.fontcolor=@color_hex[:red]
				@end_label.text="LOSE!"
			end
			clear_line()
		end
	end
end

mm = MasterMind.new(700, 950, true)
mm.show

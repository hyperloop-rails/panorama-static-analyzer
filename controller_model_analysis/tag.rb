class Tag
	attr_accessor :filename, :start_line, :start_offset, :end_line, :end_offset, :name, :id
	def initialize(filename, name)
		@filename = filename
		@name = name
	end
	def self_print
		puts "#{@filename} #{@name} #{@start_line}_#{start_offset} #{end_line}_#{end_offset}"
	end
	def toString
		"#{@filename} #{@name} #{@start_line}_#{start_offset} #{end_line}_#{end_offset}"
	end
end
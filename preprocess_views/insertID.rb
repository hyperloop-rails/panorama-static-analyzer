load 'util.rb'
def readChar(f)
	if(f.eof?)
		exit
	end
	return f.readchar
end
#input_file = ARGV[0]
def insertID(input_file)
  output_file = input_file + ".tmp"
  #puts input_file
  fout = File.open(output_file, 'w+')
  string_buffer = ""
  start = false
  File.open(input_file,'r') do |f|
     line = 1
     cl = 1
     a = readChar(f)
     b = readChar(f)
     fout.write(a)
     while (!f.eof?)
        if (a == '<' and b =~/[A-Za-z]/)
          #string_buffer +=  a
          a = b 
          b = readChar(f)
          #fout.write(a)
          string_buffer +=  a
          while( !(a != '%' and b == '>'))
            a = b
            b = readChar(f)
            string_buffer += a
            #fout.write(a)
          end
          if($layout )
              if(string_buffer.include?"body")
                start = true
              end
          end
          #puts "start : #{start}"
          string_buffer = string_buffer.gsub(/id='insert.*'/, "")
          #puts "string_buffer #{string_buffer}"
          if((!$layout or start) and !string_buffer.match(/id[\s]*=/) and !string_buffer.include?'<script' and !string_buffer.include?'<br')
            #fout.write(" id='insert#{$id}'")
            id_index = string_buffer.index(" ")
            #puts "id_index: #{id_index} #{string_buffer}"
            if id_index
              string_buffer.insert(id_index, " id='insert#{$id}'") 
            else
              string_buffer.insert(-1, " id='insert#{$id}'") 
            end
            $id += 1
          end
          fout.write(string_buffer)
          string_buffer = ""
          a = b
          b = readChar(f)
          fout.write(a)
        else 
          a = b
          b = readChar(f)
          fout.write(a)
        end
     end
     fout.write(b)
  end
  system("mv #{output_file} #{input_file}")
end
def read_view_files(dir)
  $id = 0
  if File.file?(dir)
    insertID(dir.to_s)
  end
  root, files, dirs = os_walk(dir)
  for filename in files
    if filename.to_s.end_with?("html.erb")
      $layout = false
      puts "filename is : #{filename.to_s}"
      if filename.to_s.include?("/layouts/")
        $layout = true
        #puts "$layout is true"
      end
      puts "insert"
      insertID(filename.to_s)
    end
  end
end
read_view_files(ARGV[0])

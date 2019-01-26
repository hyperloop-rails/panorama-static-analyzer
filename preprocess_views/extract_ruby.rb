def readChar(f)
	if(f.eof?)
		exit
	end
	return f.readchar
end
input_file = ARGV[0]
output_file = ARGV[1]
line_file = output_file + ".line"
puts input_file
fout = File.open(output_file, 'w+')
lineout = File.open(line_file, 'w+')
File.open(input_file,'r') do |f|
   line = 1
   cl = 1
   a = f.readchar
   b = f.readchar 
   c = f.readchar 
   if(a == "\n")
    line += 1
   end
   while (!f.eof?)
    if (a == '<' && b == '%')
      if (c == '=' || c == '-')
		    a = readChar(f)
        b = readChar(f)
   	  	c = readChar(f)
        if(a == "\n")
          result = "#{line} 1\n"
          lineout.write(result)
          line += 1
          cl += 1
        end
        while ((a != '%' or b != '>') and(a != '-' or b != '%' or c != '>'))
          fout.write(a)
          a = b
          b = c
		      c = readChar(f)     
          if(a == "\n")
            result = "#{line} 1\n"
            lineout.write(result)
            line += 1
            cl += 1
          end
        end   
        fout.write("\n")
        result = "#{line} 1\n"
        lineout.write(result)
        cl += 1   
        if (c != '>') 
          a = c
        else 
			    a = readChar(f)    
        end
        if(a == "\n")
            line += 1
        end
    		b = readChar(f)    
    		c = readChar(f)    
      elsif (c == '#') 
        b = c
        a = b
		    c = readChar(f)    
        if(a == "\n")
          line += 1
        end
      else 
        a = c
     		b = readChar(f)       
    		c = readChar(f)    
        if(a == "\n")
          result = "#{line} 1\n"
          lineout.write(result)
          line += 1
          cl += 1
        end
        while ((a != '%' || b != '>') && (a != '-' || b != '%' || c != '>'))
          fout.write(a)
          a = b
          b = c        
		      c = readChar(f)    
          if(a == "\n")
            result = "#{line} 0\n"
            lineout.write(result)
            line += 1
            cl += 1
          end
        end  
        fout.write("\n")
        result = "#{line} 0\n"
        lineout.write(result)
        cl += 1
        if (c != '>')
          a = c
        else         
			    a = readChar(f)    
        end
        if(a == "\n")
            line += 1
        end
    		b = readChar(f)          
    		c = readChar(f)    
      end
    else 
      a = b
      b = c        
   	  c = readChar(f)
      if(a == "\n")
          line += 1
      end
    end
  end
end


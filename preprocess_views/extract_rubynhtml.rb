def readChar(f)
  if(f.eof?)
    exit
  end
  char = f.readchar
  return char
end
def newLine
  $line += 1
  $offset = 0
end
input_file = ARGV[0]
output_file = ARGV[1]
$id = 0
line_file = output_file + ".line"
tag_file = output_file + ".tag"
####putsinput_file
$fout = File.open(output_file, 'w+')
lineout = File.open(line_file, 'w+')
tagout = File.open(tag_file, 'w+')
string_buffer = ""
tags = []
end_tag = ""
start_ruby = 0
start_tag = 0
$line = 1
isDisplay = 0
ruby_buffer = ""
$cl = 1
write_buffer = ""
single_tag = ["br", "br/", "img", "html", "head", "title", "meta", "link", "script"]
$offset = 0
start_offset = 0
start_line = 0
tagout_hash = {}
if !File.exists?input_file
  #puts"#{input_file} doesn't exist"
  exit
end
File.open(input_file,'r') do |f|
   a = readChar(f)
   $offset += 1
   newLine if a == "\n"
   b = readChar(f)
   c = readChar(f) 
   while (!f.eof? or (b == "%" and c== ">") or (a == '-' and b == "%" and c== ">"))
    ##puts"$line: #{$line}"
    if (a == '<' and b =~/[A-Za-z]/) and start_ruby == 0
      ##puts"abc: #{a}#{b}#{c}"
      start_offset = $offset
      start_line = $line
      string_buffer = a + b + c
      a = b 
      b = c
      c = readChar(f)
      $offset += 1
      #puts"1: $offset : #{$line}_#{$offset}"
      newLine if a == "\n"
      string_buffer += c
      start_tag = 1
    elsif b != '%' and b != '=' and c == '>' and start_ruby == 0 and  start_tag == 1
      ##puts"string_buffer #{string_buffer}"
      tag = string_buffer.split(" ")[0].gsub("<", "").gsub(">", "")
      match_id = string_buffer.match(/\sid\s*=\s*['"][^'"]*['"]/)
      id = ""
      if match_id
        id = match_id[0].split("=")[1].gsub("\"", "").gsub("'", "")
      end
      ##puts"tag_id : #{tag} #{id}"
      if !single_tag.include?tag
        tags << [tag, id]
        tagout_hash["#{tag}##{id}"] = [start_line, start_offset]
      end
      ####puts"tag #{[tag, id]}"
      a = b
      b = c
      c = readChar(f)
      $offset += 1
      #puts"2: $offset : #{$line}_#{$offset}"
      newLine if a == "\n"
      ###puts"ID: #{id} #{string_buffer} WB:#{write_buffer} END"
      write_buffer = write_buffer.gsub("remainToWrite", tags.map{|t| "#{t[0]}##{t[1]}"}.join(" "))
      lineout.write(write_buffer)
      write_buffer = ""
      start_tag = 0
      string_buffer = ""
    elsif (a == '<' and b == '/') and start_ruby == 0
      end_tag += c
      a = b 
      b = c
      c = readChar(f)
      $offset += 1
      #puts"3: $offset : #{$line}_#{$offset}"
      newLine if a == "\n"

      while(c != '>')
        end_tag += c
        a = b
        b = c
        c = readChar(f)
        $offset += 1
        #puts"4: $offset : #{$line}_#{$offset}"
        newLine if a == "\n"
      end
      ##puts"end_tag #{end_tag} #{tags.map{|t| "#{t[0]}##{t[1]}"}.join(" ") if tags[-1]} #{$line} #{$offset}"

      #tag_name = tags.map{|t| "#{t[0]}##{t[1]}"}.join(" ")
      if tags and tags.length > 0
        tag_name = "#{tags[-1][0]}##{tags[-1][1]}"
        tagout_hash[tag_name] += [$line, $offset+2]
        #tagout.write("#{tag_name}\t#{$line}_#{$offset+2}\n")
        tags.pop
        end_tag = ""
      end
    elsif( a == '<' and b == '%')
      start_ruby = 1
      if (c == '=' or c == '-')
        a = readChar(f)
        b = readChar(f)
        c = readChar(f)
        $offset += 3
        # a = b 
        # b = c 
        # c = readChar(f)
        # $offset += 1
        #puts "8: $offset : #{$line}_#{$offset}"
        ruby_buffer = a + b + c
        string_buffer += a + b + c if start_tag == 1
        #string_buffer += a  if start_tag == 1
        isDisplay = 1
        #newline_count = ruby_buffer.count("\n")
        if(a == "\n")
          #$fout.write("+++ #{$cl} #{$line}")
          if(start_tag == 1)
            write_buffer += "#{$line}\t#{isDisplay}\tremainToWrite\n"
          else
            result = "#{$line}\t#{isDisplay}\t#{tags[-1]? tags.map{|t| "#{t[0]}##{t[1]}"}.join(" ") : 'null' }\n"
            lineout.write(result)
          end
          $cl += 1
          newLine
         
         end
        $fout.write(a)
      elsif (c == '#') 
        a = b
        b = c
        c = readChar(f)  
        $offset += 1
        #puts"5: $offset : #{$line}_#{$offset}"
        newLine if a == "\n"  
        string_buffer += c
      else
        if(c == "\n")
          #$fout.write("--- #{$cl} #{$line}")
          if(start_tag == 1)
            write_buffer += "#{$line}\t#{isDisplay}\tremainToWrite\n"
          else
            result = "#{$line}\t#{isDisplay}\t#{tags[-1]? tags.map{|t| "#{t[0]}##{t[1]}"}.join(" ") : 'null' }\n"
            lineout.write(result)
          end
          #$line += 1
          newLine
          $cl += 1
          $fout.write(c)
        end
        
        isDisplay = 0
        a = readChar(f)
        b = readChar(f)
        c = readChar(f)
        $offset += 3
        #puts"9: $offset : #{$line}_#{$offset}"
        #puts "A#{a}B#{b}C#{c}&&"
        string_buffer += a + b + c if start_tag == 1
        ruby_buffer += a + b + c
        # a = b
        # b = c 
        # c = readChar(f)
        # $offset += 1
        # string_buffer += a if start_tag == 1
        # ruby_buffer += a 
        ###puts"ruby_buffer #{ruby_buffer}"
        if(a == "\n")
          #$fout.write("--- #{$cl} #{$line}")
          if(start_tag == 1)
            write_buffer += "#{$line}\t#{isDisplay}\tremainToWrite\n"
          else
            result = "#{$line}\t#{isDisplay}\t#{tags[-1]? tags.map{|t| "#{t[0]}##{t[1]}"}.join(" ") : 'null' }\n"
            lineout.write(result)
          end
          #$line += 1
          newLine
          $cl += 1
        end
        $fout.write(a)
      end    
    elsif ((b == '%' and c == '>') or (a == '-' and b == '%' and c == '>'))
        $fout.write("\n")
        ###puts"last: #{ruby_buffer}\n abc: #{a}#{b}#{c}\n"
        start_ruby = 0
        ruby_buffer = ""
        if(start_tag == 1)
          write_buffer += "#{$line}\t#{isDisplay}\tremainToWrite\n"
        else
          lineout.write("#{$line}\t#{isDisplay}\t#{tags[-1]? tags.map{|t| "#{t[0]}##{t[1]}"}.join(" ") : 'null' }\n")
        end
        # a = readChar(f) 
        # b = readChar(f) 
        # c = readChar(f)  
        a = b
        b = c
        c = readChar(f)

        $offset += 1
        #puts"6: $offset : #{$line}_#{$offset}"
        if start_tag == 1
          #string_buffer += a + b + c 
          string_buffer += c
          ###puts"start_tag: #{start_tag} #{string_buffer}"
        end
        $cl += 1
        newLine if a == "\n"
    else
      a = b
      b = c
      c = readChar(f)

      $offset += 1
      #puts"7: $offset : #{$line}_#{$offset}"
      string_buffer += c if start_tag == 1
      ruby_buffer += c if start_ruby == 1
      if(start_ruby == 1)
        if(a == "\n")
          if(start_tag == 1)
            write_buffer += "#{$line}\t#{isDisplay}\tremainToWrite\n"
          else
            result = "#{$line}\t#{isDisplay}\t#{tags[-1]? tags.map{|t| "#{t[0]}##{t[1]}"}.join(" ") : 'null' }\n"
            lineout.write(result)
          end
          newLine 
          $cl += 1
        end
        $fout.write(a) if !(a=='-' and b=='%' and c=='>')
        ##puts"---2 #{a}#{b}#{c}" if a == '-'

      else
        newLine if(a == "\n")
      end 

    end
   end
end
tagout.write(tagout_hash)
$fout.close
lineout.close
tagout.close
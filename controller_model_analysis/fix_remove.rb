def fix_remove(tag, v, dependencies)
	instr = v[0].getInstr
	tag_file = $of + "app/" + instr.ln[0]
	debug_info(tag_file)
	puts "fix_remove"
	tag.self_print
	if  !File.exists?tag_file
		debug_info("file: #{tag_file} doesn't exist")
		return
	end
	ori_contents = open(tag_file).read.lines
	debug_info("****SAME SETS ONLY DELETE THE TAG****")
	sl = tag.start_line - 1
	so = tag.start_offset - 1
	el = tag.end_line - 1
	eo = tag.end_offset
	delete_contents = ""
	if el > sl
		delete_contents += ori_contents[sl][so..-1]
		ori_contents[sl][so...-1] = ""
		tag.self_print
		for i in (sl+1)...el
			if ori_contents[i]
				delete_contents += ori_contents[i] 
				ori_contents[i] = "\n"
			end
		end
		if ori_contents[el] and ori_contents[el][0...eo]
			delete_contents += ori_contents[el][0...eo]  
			puts "last line #{ori_contents[el][0...eo]}"
			ori_contents[el][0...eo] = ""
		end
	elsif el == sl
		ori_length = ori_contents[sl].length
		delete_contents += ori_contents[sl][so...eo]
		ori_contents[sl][so...eo] = ""
		puts "eo #{eo} ori_contents.sl.length #{ori_length}"
		if eo > ori_length
			ori_contents[sl][so...eo] = "\n"
		end
	end
	debug_info("------#{delete_contents}------")
	view_contents = ori_contents.join
	debug_info(view_contents)
	code_file_snippets = []
	if v != dependencies
		# there are no nodes outside the div
		debug_info("****SOME NODES OUTSIDE THE TAG****")
		outside = dependencies - v
		codes = outside.group_by{|x| x.getInstr.ln[0]}
		codes.each do |k, nodes|
			code_file = $of + "app/" + k
			if k.include?'models'
				next
			end
			puts "code_file #{code_file}"
			next unless File.exists?code_file
			code_contents = open(code_file).read.lines	
			puts "beforeloop"		
			nodes.group_by{|x| x.getInstr.ln[1]}.each do |loc, slices|
				debug_info("#{code_file} #{loc}")
			
				ori_snippet = code_contents[loc-1].strip
				expr = ori_snippet.gsub(" ",".*")
				back_snippet = construct(slices)
				if(back_snippet[/#{expr}/])
					debug_info("matched")
					code_contents[loc-1] = code_contents[loc-1].gsub(ori_snippet, "")
					#debug_info(code_contents)
					#debug_info("#{code_file} #{code_contents.join}")

				end
				debug_info("#{ori_snippet} #{back_snippet}")
			end
			code_file_snippets << [code_file, code_contents]
		end
	end
	code_file_snippets << [tag_file, ori_contents]
	#write_code2file(code_file_snippets)
	return code_file_snippets
end
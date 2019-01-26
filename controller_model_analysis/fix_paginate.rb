def fix_paginate(parent_instr, query,loop_type='each')
	puts "fix_paginate #{parent_instr.toString} loop_type:#{loop_type} #{parent_instr.ln}"
	# find the location of loop header
	pln = parent_instr.ln
	qln = query.getInstr.ln

	# go to the view file
	loop_file = $of + "app/" + pln[0]
	ls = open(loop_file).read.lines
	# get the source code according to the line number
	code = ls[pln[1] - 1]
	variable = ""
	tag = parent_instr.tag_node
	# puts "#{ls[tag.start_line-1][tag.start_offset-1..tag.start_offset+2]}"
	# puts "#{ls[tag.end_line-1][tag.end_offset-1]}"
			
	#tag.self_print
	puts "code #{code}"
	code.split(" ").each do |snippet|
		if !loop_type or loop_type.include?'each'
			if snippet.include?"\.each"
				puts snippet 
				index_each = snippet.index('.each')
				variable = snippet[0...index_each]
				break
			elsif snippet.include?"for " and snippet.include?" in "
				index_in = snippet.index(' in ')
				variable = snippet[index_in + 4..-1]
				break
			end
		elsif loop_type.include?'map'
			if snippet.include?"\.map"
				puts snippet 
				index_each = snippet.index('.map')
				variable = snippet[0...index_each]
			end
		end
	end
	code_file_snippets = []
	param = ".paginate(:page => params[:page], :per_page => 10)"
	if variable != ""
		# puts "variable: #{variable}"
		s = ls[tag.end_line-1]
		puts s
		space_num = s.index(s.lstrip[0])
		space_string = ls[tag.end_line-1][0...space_num]
		if variable.include?"\."
			head_s = ls[tag.start_line-1]
			puts "head_s: #{head_s}"
			head_space_num = head_s.index(head_s.lstrip[0])
			head_space_string = ls[tag.start_line-1][0...head_space_num]
			new_vname = variable.downcase.gsub(".", "_")
			new_vname = new_vname.gsub(/[^a-z0-9_]/,'')
			new_statement = "<% #{new_vname} = #{variable}#{param} %>\n#{head_space_string}"
			
			will_string = "\n#{space_string}<%= will_paginate #{new_vname} %>"
 			ls[pln[1] - 1] = ls[pln[1] - 1].gsub(variable, new_vname)
			ls[tag.end_line-1].insert(tag.end_offset, will_string)
			ls[tag.start_line-1].insert(tag.start_offset - 1, new_statement)
			view_contents = ls.join
			#write to the view file
			#open(loop_file, 'w').write(view_contents) if !$debug
			code_file_snippets << [loop_file, ls]
			debug_info(view_contents)
			debug_info(new_statement)
			# it's a query chain	
		else
			# it's variable
			#puts "qln #{qln}"
			# get the file of query
			#query_file = $of + "app/" + qln[0]
			#puts "query_file #{query_file}"
			#qs = open(query_file).read.lines
			# get the source code of the query according to the line number
			#qcode = qs[qln[1] - 1]
			# puts "qcode: #{qcode}"
			# code should be of type: variable.*=.*query.function
			#query_function = query.getInstr.getFuncname 
			#query_snippet = qcode[/#{variable}.*=.*#{query_function}/]
			head_s = ls[tag.start_line-1]
			head_space_num = head_s.index(head_s.lstrip[0])
			
			head_space_string = ls[tag.start_line-1][0...head_space_num]
			new_statement = "<% #{variable} = #{variable}#{param} %>\n#{head_space_string}"
			ls[tag.start_line-1].insert(tag.start_offset - 1, new_statement)
			debug_info("new_statement #{new_statement}")
			#paginate_query = query_snippet + param
			#qs[qln[1] - 1] = qs[qln[1] - 1].gsub(query_snippet, paginate_query)
			#query_contents = qs.join
			#debug_info(query_contents)
			tag.self_print
			will_string = "\n#{space_string}<%= will_paginate #{variable} %>"
			ls[tag.end_line-1].insert(tag.end_offset, will_string)
			# write to the view file and the query file
			# code_file_snippets << [query_file, qs]
			puts ls.join if $debug
			code_file_snippets << [loop_file, ls]
		end
	end
	return code_file_snippets
	#write_code2file(code_file_snippets)
end
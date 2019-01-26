def fix_approximate(view_node, query,variable=nil)
	puts "fix_approximate variable is : #{variable}"
	vln = view_node.getInstr.ln
	qln = query.getInstr.ln
	view_file = $of + "app/" + vln[0]
	vs = open(view_file).read.lines
	vcode = vln[-1].strip if vln.length >= 5
	if variable
		vcode = variable
	end
	tag = view_node.getInstr.tag_node

	code_file_snippets = []
	if tag == nil
		return code_file_snippets
	end
	if view_node == query
		#puts "query is used by itself"
		head_s = vs[tag.start_line-1]
		head_space_num = head_s.index(head_s.lstrip[0])
		head_space_string = vs[tag.start_line-1][0...head_space_num]
		query_function = query.getInstr.getFuncname
		limit_query = vcode.gsub("\.#{query_function}", "\.limit(10)\.#{query_function}")
		new_vname = vcode.downcase.gsub(".", "_")
		puts "new_vname #{new_vname} vvv"
		new_statement = "<% #{new_vname} = #{limit_query} %>\n#{head_space_string}"
		#app_statement = "#{new_vname}<10?#{new_vname}:'more than 10'"
		app_statement = get_app_statements(new_vname, query_function)
		puts "#{new_statement}"
		vs[tag.start_line-1].insert(tag.start_offset - 1, new_statement)
		vs[vln[1] - 1] = vs[vln[1] - 1].gsub(vcode, app_statement)
		view_contents = vs.join
		debug_info(view_contents)
		#open(view_file,'w').write(view) if !$debug
		code_file_snippets << [view_file, vs]
	else
		#puts "query is not used by itself"
		query_file = $of + "app/" + qln[0]
		#puts "query_file #{query_file}"
		qs = open(query_file).read.lines
		# get the source code of the query according to the line number
		qcode = qln[-1].strip if qln.length >= 5
		query_function = query.getInstr.getFuncname 
		
		puts "qcode #{vcode} #{qcode}"
		limit_query = qcode.gsub("\.#{query_function}", "\.limit(10)\.#{query_function}")
		# puts "qcode: #{qcode}"
		# code should be of type: variable.*=.*query.function
		#app_statement = "#{vcode} < 10?#{vcode}:'more than 10'"
		app_statement = get_app_statements(vcode, query_function)
		view_source = vs[vln[1] - 1] 
		[" ", "=>", "(", "["].each do |symbol|
			replace_var = symbol + vcode
			if view_source.index(replace_var)
				puts "replace_var #{replace_var}"
				view_source = view_source.gsub(replace_var, symbol + app_statement)
			end
			puts "view_source #{view_source}"
		end
		vs[vln[1] - 1] = view_source
		puts "vs[vln[1] - 1] #{vs[vln[1] - 1]}"
		#vs[vln[1] - 1] = vs[vln[1] - 1].gsub(vcode, app_statement)
		qs[qln[1] - 1] = qs[qln[1] - 1].gsub(qcode, limit_query)
		view_contents = vs.join
		query_contents = qs.join
		puts view_contents
		puts query_contents
		# open(view_file,'w').write(view_contents) if !$debug
		# open(query_file,'w').write(query_contents) if !$debug
		code_file_snippets << [view_file, vs]
		code_file_snippets << [query_file, qs]
	end
	#write_code2file(code_file_snippets)
	return code_file_snippets
end

def get_app_statements(new_vname, funcname)
	if funcname == 'count'
		return "#{new_vname}<10?#{new_vname}:'more than 10'"
	elsif funcname == 'sum'
		return "more than #{new_vname}"
	elsif funcname == 'maximum'
		return ">= #{new_vname}"
	elsif funcname == 'minimum'
		return "<= #{new_vname}"
	elsif funcname == 'average'
		return "around #{new_vname}"
	end	
end

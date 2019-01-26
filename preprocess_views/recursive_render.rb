def solve_all_renders
	$actions.each do |k, a|
		##puts "@@@@@ #{a.name} #{a.is_entrance} #{a.has_non_default_or_layout_render}"
		if a.is_entrance or a.has_non_default_or_layout_render or (a.render_stmts.length > 0 and a.render_stmts[0].is_default)
			con = solve_render_for_action(a)
			a.replaced_code = con 
			# if $only_generate_nextcall == false
			# 	#puts "Action: #{a.controller.name}.#{a.name} renders:"
			# 	str = ""
			# 	a.render_stack.each do |r|
			# 		#puts "\t#{r.render_file}"
			# 		str += "\n"
			# 		str += r.get_content
			# 	end
			# 	str += "\n"
			# 	a.replaced_code = con 
			# end
		end
	end
end


def replace_files
	#TODO: mkdir
	$controllers.each do |k, v|
		fp = File.open("#{v.file_name}","r")
		content = fp.read
		##puts "CONTENT #{content}"
		dic = create_dic(v.file_name, content)
		original = dic.dup
		fp.close
		sorted_actions = v.actions.sort_by {|a| -a.astnode.line}
		sorted_actions.each do |a|
			if a.render_stack.length > 0 and  a.replaced_code.length > 0
				##puts "Replace #{a.controller.name}.#{a.name}"
				k = a.astnode.parent.source
				content[k] = "#{a.replaced_code[0]}"
				# deal with move of the class controller 
				start = a.astnode.parent.line
				# puts "START #{start} #{k}"
				l = k.lines.count
				dic2 = a.replaced_code[1]
				dic = insert2(dic, dic2, start, l)

			end
		end
		# delete the comments and space
		content, dic = deleteComments(content, dic)
		##puts "FINAL #{dic.length} #{dic.sort}"
		new_file_name = v.file_name.gsub($controller_folder_name, $new_controller_folder_name)
		##puts "Rewriting #{new_file_name}"
		file_path = new_file_name.gsub(File.basename(new_file_name),'')
		run_command("mkdir -p #{file_path}")
		File.write("#{new_file_name}", content)
		
		line_file_name = new_file_name + ".line"
		##puts line_file_name
		File.write("#{line_file_name}", dic.sort.to_h)
		ast = YARD::Parser::Ruby::RubyParser.parse(File.open(new_file_name, "r").read)
	end
	
	if $has_helper
		$helpers.each do |k, v|
			fp = File.open("#{v.file_name}","r")
			content = fp.read
			fp.close
			dic = create_dic(v.file_name, content)
			v.actions.each do |a|
				if a.render_stack.length > 0 and  a.replaced_code.length > 0
					k = a.astnode.parent.source
					content[k] = "#{a.replaced_code[0]}"
					# deal with move of the class controller 
					start = a.astnode.parent.line
					l = k.lines.count
					dic2 = a.replaced_code[1]
					dic = insert2(dic, dic2, start, l)			
				end
			end
			content, dic = deleteComments(content, dic)	
			new_file_name = v.file_name.gsub($helper_folder_name, $new_helper_folder_name)
			##puts "Rewriting #{new_file_name}"
        	file_path = new_file_name.gsub(File.basename(new_file_name),'')
        	run_command("mkdir -p #{file_path}")
			File.write("#{new_file_name}", content)
			
			line_file_name = new_file_name + ".line"
			##puts line_file_name
			File.write("#{line_file_name}", dic)

			ast = YARD::Parser::Ruby::RubyParser.parse(File.open(new_file_name, "r").read)

		end
	end
end

def solve_render_for_action(action)
	#first, check layout
	
	#then check render stmt
	puts "action.name #{action.controller.file_name} #{action.name}"
	exist_render = false
	# put the whole action's code as the source
	ast_node = action.astnode.parent
	str = ast_node.source
	# start position of this action inside the controllers
	sp = ast_node.line
	##puts "action ssss #{sp} #{ast_node.source}"
	dic = create_dic(action.controller.file_name, str, sp)
	ar = action.render_stmts
	# sort the action buy it's line_range, so that the order will not change
	valid_stmts = action.render_stmts.select {|rs| rs.valid_file_path && rs.astnode}
	rss = valid_stmts.sort_by {|rs| -rs.astnode.line_range.to_a.last}
	#puts "CON #{action.controller.name} #{action.name} \n"
	rss.each do |r|
		puts "loop 1"
		if r.valid_file_path
			if(r.astnode)
				puts "r.valid_file_path #{r.valid_file_path}"
				action.push_to_render_stack(r)
				if !r.render_file.include?"layout"
					t = action.get_default_render
					puts "t: #{t.render_file} r: #{r.render_file}" if t
					if t and t.render_file == r.render_file
						exist_render = true
					end
				end
				#puts "Controller.action\n#{r.action.controller.name} #{r.action.name} "
				
				s, dic2 = solve_render_for_view(action, r)
				start = r.astnode.line_range.to_a.last - sp 

				puts "VIEW #{r.render_file} START: #{start}\n #{r.astnode.source}"
				begin
					tmp = insertString(str, start, s)
					YARD::Parser::Ruby::RubyParser.parse(tmp)
					str = tmp
					dic = insert(dic, dic2, start)
					#puts "YES: #{tmp}"
				rescue
					puts "RESCUE1: #{tmp}"
				end
				if action.controller.file_name.include?'fulcrum' and action.controller.name == 'StoriesController' and action.name == 'index'
					if r.render_file.include?"stories/_story.html.erb"
						begin
							tmp = str.lines[0...-1].join(' ') + s + str.lines[-1]
							YARD::Parser::Ruby::RubyParser.parse(tmp)
							str = tmp
							dic = insert(dic, dic2, dic.length - 1)
							#puts "tmp:#{tmp} dic: #{dic.sort.to_h}"
						rescue
							puts "Rescue2"
						end	
					end
				end
			end
		end
		puts "end loop1"
	end
	#if no exist render, check default render
	if exist_render == false
		puts "loop 2"
		t = action.get_default_render
		# puts "#{action.controller.name} #{action.name}"
		# puts "Exist render is false" #unless action.exist_template
		# puts "t: #{t}"
		if t #action.exist_template
			action.push_to_render_stack(t)
			# start = action.astnode.line_range.to_a.last - sp
			#puts "BEFORE END #{action.name}"
			s, dic2 = solve_render_for_view(action, t)
			#puts "s: #{s}"
			begin
				tmp = str.lines[0...-1].join(' ') + s + str.lines[-1]
				YARD::Parser::Ruby::RubyParser.parse(tmp)
				str = tmp
				dic = insert(dic, dic2, dic.length - 1)
				#puts "tmp:#{tmp} dic: #{dic.sort.to_h}"
			rescue
				puts "Rescue2: #{tmp}"
			end
		end
	end
	if action.use_layout and action.controller.exist_layout
		# puts "#{action.name} USELAYOUT: yes #{action.controller.get_layout.render_file}"
		action.push_to_render_stack(action.controller.get_layout)
		s, dic2 = solve_render_for_view(action, action.controller.get_layout)
		begin
			tmp = str.lines[0...-1].join(' ') + s + str.lines[-1]
			YARD::Parser::Ruby::RubyParser.parse(tmp)
			str = tmp
			dic = insert(dic, dic2, dic.length - 1)
			#puts "tmp:#{tmp} dic: #{dic.sort.to_h}"
		rescue
			#puts "Rescue"
		end		
	end


	return str, dic
end

#recursively...
def solve_render_for_view(action, re)
	view_file = re.render_file
	viewf = find_view_file(view_file)
	#puts view_file
	dic = {}
	if viewf

		puts "VIEW_FILE: #{view_file}"
		str = viewf.get_content
		dic = create_dic(view_file, str)
		code = ""
		offset = 0
		if re.object
			fn = view_file.split("/")[-1]
			on = fn.split(".")[0]
			if on[0] == "_"
				on[0] = ""
			end
			try = code + "#{on} = #{re.object}\n"
			begin
				ast = YARD::Parser::Ruby::RubyParser.parse(try)
				code = try
				#puts "ast: #{ast}"
				dic = insertRender(dic)
				offset += 1
				#puts "YES:\n#{try} #{re.locals} #{code}"
			rescue
				#puts "TRY:\n'#{try}'"
			end
		end
		if re.locals
			for k in re.locals.keys()
				v = re.locals[k]
				if k == v
					next
				end
				try = code + "#{k} = #{v}\n"
				begin
					ast = YARD::Parser::Ruby::RubyParser.parse(try)
					code = try
					#puts "ast: #{ast}"
					dic = insertRender(dic)
					offset += 1
					#puts "YES:\n#{try} #{re.locals} #{code}"
				rescue
					#puts "TRY:\n'#{try}'"
				end
			end
		end
		if not (re.locals or re.collection)
			for k in re.properties.keys()
				v = re.properties[k]
				if k == v
					next 
				end
				#puts "properties: #{k} #{v}"
				if not ["partial", "template", "action", "", "layout"].include?k
					try = code + "#{k} = #{v}\n"
					begin
						YARD::Parser::Ruby::RubyParser.parse(try)
						code = try
						dic = insertRender(dic)
						offset += 1
					rescue
					end
				end
			end
		end
		if re.collection
			if re.as
				code += "#{re.collection}.each do |#{re.as}|\n"
				offset += 1
			else
				code += "#{re.collection}.each do\n"
				offset += 1
			end
			dic = insertRender(dic)
			code += viewf.get_content
			code += "end\n"
			lk = dic.keys.sort()[-1]
			dic[lk + 1] = nil

		else
			code += viewf.get_content
		end
		str = code
		puts "STRING: #{str} ****"
		# .gsub($new_view_folder_name, $view_folder_name)	
		if viewf.render_stmts.length == 0
			#return viewf.get_content, dic
			puts "no more recursively"
			return code, dic
		end
		rss = viewf.render_stmts.sort_by {|rs| -rs.astnode.line_range.to_a.last}
		
		rss.each do |r|
			# recursively rendering
			
			if r.valid_file_path && r.render_file != view_file
				s, dic2 = solve_render_for_view(viewf, r)
				start = r.astnode.line_range.to_a.last + offset
				puts "start is : #{start} #{view_file} #{r.astnode.source}"
			  	begin
					tmp = insertString(str, start, s)			  
					YARD::Parser::Ruby::RubyParser.parse(tmp)
					str = tmp
					dic = insert(dic, dic2, start)
					puts "final_str #{str}"
				rescue
					puts "RESCUERESCUE #{tmp} \n\tSTARTSTART: #{str}\n\tENDEND\n\tSTARTSTART: #{s}\n\tENDEND\n"
				end
				#end
			end 
		end

		return str, dic
	end

	return '', dic
end

def insert(dic, dic2, start)
	# sort the dic
	dic = dic.sort.to_h
	dic2 = dic2.sort.to_h
	length = dic2.length
	render_position = dic[start].dup
	dic2.each do |k, v|
		unless v
			dic2[k] = render_position
		end
	end
	dic_dup = dic.clone
	for key in dic.keys()
		if key > start
			dic[key + length] = dic_dup[key]
		end
	end
	i = 1
	for key in dic2.keys()
		dic[start + i] = dic2[key]
		i += 1
	end
	return dic
end

def insert2(dic, dic2, start, l)
	dic = dic.sort.to_h
	dic2 = dic2.sort.to_h
	length = dic2.length
	dic_dup = dic.clone
	for key in dic.keys()
		if key > start
			dic[key + length - l] = dic_dup[key]
		end
	end
	i = 0
	for key in dic2.keys()
		dic[start + i] = dic2[key]
		i += 1
	end
	
	return dic
end

def deleteLine(dic, l)
	# sort the key so that they can be moved up by 1
	for key in dic.keys().sort
		if key > l
			dic[key - 1] = dic[key]
		end
	end
	# delete the last key
	dic.delete(key)
	return dic
end
def insertRender(dic)
	dic_dup = dic.dup
	for key in dic.keys().sort
		dic[key+1] =dic_dup[key]
	end
	dic[1] = nil
	return dic
end
def deleteComments(str, dic)
	re = ""
	ls = str.lines
	length = ls.length
	for i in 1..length
		index = length - i
		line = ls[index]
		if !line.strip.start_with?("#") && line.strip != ''
			re = line + re
		else
			dic = deleteLine(dic, index + 1 )
		end
	end
	return re, dic
end
def create_dic(view_file, code, start = 1, ss = 1)
	dic = {}
	l = code.lines.count
	for i in start..(start + l - 1)
		dic[i - start + 1] = [view_file, i]
	end
	return dic
end

def insertString(str, ln, content)
	ls = str.lines
	re = ""
	for i in 1..ln
	
		con = ls[i - 1]
		
		re = re + con
		
	end
	puts "re ln #{ln} #{str} #{str[ln-1]}"
	re += content
	
	for i in (ln + 1)..ls.length
	
		con = ls[i - 1]
		re = re + con
	end
	
	re
end 
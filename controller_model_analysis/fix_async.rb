def fix_async(tag, v, dependencies)
	# controller file
	puts "fix_async"
	if !$con_name 
		return []
	end
	controller =$class_map[$start_class]
	debug_info(controller.getName)
	copy_con = controller.filename
	con_filename = $of + "app/controllers/" + copy_con.split("merged_controllers/")[-1]
	#debug_info(con_filename)
	routes_file = $of + "config/routes.rb"
	return unless File.exists?routes_file
	return unless File.exists?con_filename
	con_contents = open(con_filename).read.lines
	end_con = con_contents.reverse.detect{|l| l.include?("end")}
	end_con_loc = con_contents.rindex(end_con)

	#debug_info("end loc : #{end_con_loc}")
	
	new_act_name = "#{tag.name.gsub(/[^a-zA-Z]/, '')}"
	new_act_contents = "\tdef #{new_act_name}\n"
	render_async_path = "<%= render_async #{new_act_name}_path%>"
	#debug_info("new_act_name : #{new_act_name}")
	
	rou_contents = open(routes_file).read.lines
	end_rou = rou_contents.reverse.detect{|l| l.include?("end")}
	end_rou_loc = rou_contents.rindex(end_rou)
	rou_contents[end_rou_loc] = "get :#{new_act_name}, controller: :#{$con_name}\n" + rou_contents[end_rou_loc]
	
	#debug_info("ROU_CONTENTS: #{rou_contents.join}")

	#debug_info("-----#{tag.filename}")
	tag_file = $of + "app/" + tag.filename
	#debug_info(tag_file)
	tag.self_print

	new_view = File.dirname(tag_file) + "/" + new_act_name + ".html.erb"
	new_view_tmp = new_view.split("views/")[-1]
	#debug_info("new_view_file #{new_view} #{new_view_tmp}")
	if  !File.exists?tag_file
		#debug_info("file: #{tag_file} doesn't exist")
		return
	end
	ori_contents = open(tag_file).read.lines
	sl = tag.start_line - 1
	so = tag.start_offset - 1
	el = tag.end_line - 1
	eo = tag.end_offset 
	delete_contents = ""
	if el > sl
		delete_contents += ori_contents[sl][so..-1]
		ori_contents[sl][so...-1] = "#{render_async_path}"
		for i in (sl+1)...el
			if ori_contents[i] 
				delete_contents += ori_contents[i] 
				ori_contents[i] = "\n"
			end
		end
		if ori_contents[el] and ori_contents[el][0...eo] 
			delete_contents += ori_contents[el][0...eo] 
			ori_contents[el][0...eo] = ""
		end
	elsif el == sl
		ori_length = ori_contents[sl].length
		delete_contents += ori_contents[sl][so...eo]
		ori_contents[sl][so...eo] = "#{render_async_path}"
		puts "eo #{eo} ori_contents.sl.length #{ori_length}"
		if eo > ori_length
			ori_contents[sl][so...eo] = "#{render_async_path}\n"
		end
	end
	#debug_info("------#{delete_contents}------")
	view_contents = ori_contents.join
	#debug_info(view_contents)
	code_file_snippets = []
	if v != dependencies
		# there are no nodes outside the div
		#debug_info("****SOME NODES OUTSIDE THE TAG****")
		outside = dependencies - v
		codes = outside.group_by{|x| x.getInstr.ln[0]}
		codes.each do |k, nodes|
			if k.include?'models'
				next
			end
			code_file = $of + "app/" + k
			puts "code_file #{code_file}"
			next unless File.exists?code_file
			code_contents = open(code_file).read.lines	
			if(code_contents == con_contents)
				con_contents = code_contents
			end	
			nodes.group_by{|x| x.getInstr.ln[1]}.each do |loc, slices|
				#debug_info("#{code_file} #{loc}")
			
				ori_snippet = code_contents[loc-1].strip
				expr = ori_snippet.gsub(" ",".*")
				back_snippet = construct(slices)
				if(back_snippet[/#{expr}/])
					#debug_info("matched")
					code_contents[loc-1] = code_contents[loc-1].gsub(ori_snippet, "")
					#debug_info(code_contents)
					#debug_info("#{code_file} #{code_contents.join}")

				end
				#debug_info("#{ori_snippet} #{back_snippet}")
			end
			code_file_snippets << [code_file, code_contents]
		end
	end
	new_act_contents += "\t\trender '#{new_view_tmp}'\n\tend\n"
	con_contents[end_con_loc] = new_act_contents + con_contents[end_con_loc]
	#debug_info(con_contents)
	# write to file
	con_pair = [con_filename, con_contents]
	code_file_snippets << con_pair unless code_file_snippets.include?con_pair
	code_file_snippets << [routes_file, rou_contents]
	code_file_snippets << [new_view, delete_contents.lines]
	code_file_snippets << [tag_file, ori_contents]
	
	#write_code2file(code_file_snippets)
	return code_file_snippets
end
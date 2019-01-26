def preparation(start_class, start_function)
	$start_class = start_class
	$start_function = start_function
	$con_name = start_class.split("::")[-1].gsub("Controller","").downcase
	
	filter_handler = $class_map[start_class].getMethods["before_filter"]
	$filter_functions = []
	filter_handler.getCalls.each do |f|
		#puts f.getObjName
		#puts f.getFuncName
		if f.caller
			fname = "#{f.caller.getName}.#{f.getFuncName}"
			$filter_functions.push(fname)
		end
	end
	puts $filter_functions
	puts "get into preparation"
	$choices = {}
	puts "$choices #{$choices}"
	$tag_node = {}
	$tags = {}
	$complexity = {}
	
	$tag_complexity = {}
	$tag_complexity_split = {}
	if $root == nil
		$cfg = trace_query_flow(start_class, start_function, "", "", 0)
		puts "trace_query_flow"
		addAllControlEdges
		puts "addAllControlEdges"
		compute_source_sink_for_all_nodes
		puts "compute_source_sink_for_all_nodes"
		if $cfg == nil
			puts "return because $cfg is null"
			return
		end
		if $cfg.getBB[0] == nil or $cfg.getBB[0].getInstr[0] == nil
			exit
		end
		$root = $cfg.getBB[0].getInstr[0].getINode	
	end
	
	compute_query_card_stat
	puts "compute_query_card_stat"
	computeComplexity
	puts "computeComplexity"
	$complexity = $n_c.dup
	$node_list.each do |n|
		if n.instance_of?Dataflow_edge
			next
		end

		if  n.isQuery?
			next
		else
			#$complexity[n] = 0
			if n.getInstr.instance_of?Call_instr
				puts "n.instr: #{n.getInstr.toString}"
				mcfg = n.getInstr.getCallCFG
				puts "getCallCFG: #{mcfg}"
				if mcfg
					instrs = mcfg.getAllInstrs
					instrs.each do |ins|
						ins_node = ins.getINode
						puts "ins_node #{ins.toString} #{ins_node.isQuery?}"
						if ins_node.isQuery?
							if $complexity[n]
								$complexity[n] = [$complexity[ins_node],$complexity[n]].max
							else
								$complexity[n] = $complexity[ins_node] 
							end
						end

					end
				end
			end
			puts "after functioncall $complexity[n]: #{n.getInstr.toString} complexity:#{$complexity[n]}=="

			if !$complexity[n]
				tdds = traceback_data_dep(n).select{|n| !n.instance_of?Dataflow_edge}
				#puts "-------"
				tdds.each do |tdd|
					puts "tdd.getInstr.toString4 #{tdd.getInstr.toString4}"
					if $filter_functions.include?tdd.getInstr.toString4
						next
					end
					#if !tdd.instance_of?Dataflow_edge
					puts "TDD: #{tdd.getInstr.toString} n_c is: #{$n_c[tdd]}"
					next unless tdd.isQuery?
					loops = 0
					if($complexity[n])
						$complexity[n] = [$complexity[n], $n_c[tdd] + loops].max
					else
						$complexity[n] = $n_c[tdd] + loops
					end
					#end
				end
			end
		end
		puts "$complexity[n]: #{n.getInstr.toString} complexity:#{$complexity[n]}=="
	end
	$node_list.each do |n|
		if n.instance_of?Dataflow_edge
			next
		end
		#puts "n: #{n.getInstr.toString} c: #{$complexity[n]} ="
		nln = n.getInstr.ln
		puts "nln is : #{nln} #{n.getInstr.toString} #{n}"
		if !nln or !nln[3] or nln[3] == 'null' or nln[3].end_with?"#" or  nln[3].split(" ")[-1].include?"%"
			next
		end
		puts "here #{nln}"
	
		tag_key = [nln[0],nln[3]]
		puts "tag_key #{$of} #{tag_key}"
		if !$tags[tag_key]
			puts "ele-id"
			ele_id = nln[3].split(" ")[-1]
			tag_file = $app_dir + "/ruby_" + nln[0] 
			puts "tag_file #{tag_file}"
			tag = readTagPostion(tag_file, ele_id)
			$tags[tag_key] = tag
			n.getInstr.tag_node = tag
			puts "tag #{tag}"
		else
			n.getInstr.tag_node = $tags[tag_key]
			puts "tag_node #{$tags[tag_key]}"
		end
		puts "here2"
		
	end
	$tag_node = $node_list.select{|n| n.getInstr.tag_node}.group_by{|n| n.getInstr.tag_node}

	max_com = 0
	$tag_node.each do |k, v|
		$tag_complexity[k] = -1
		$tag_complexity_split[k] = -1
		puts "TAG: -----"
		k.self_print
		if start_class == 'StoriesController' and start_function == 'edit'
			if ['div#story_box', 'a#insert512','div#insert197','a#insert194','a#insert195','a#insert191','a#insert193','div#insert435','div#insert438','div#insert448', 'a#insert198','a#insert199'].include?k.name
				$tag_complexity[k] = 0
				$tag_complexity_split[k] = 0
				next
			end
		end
		v.each do |node|
			if $complexity[node]  
				ncost = $complexity[node] 
				n_ins = node.getInstr
				if !n_ins.ln or !n_ins.ln[2] or n_ins.ln[2] != 1
					next
				end
				puts "NODE: #{node.getInstr.toString} cost: #{ncost}"
				if ncost > $tag_complexity[k]
					$tag_complexity[k] = ncost
					$tag_complexity_split[k] = ncost 
					sk = $n_split[node]
					if sk > 1
						ncost = ncost * 1.0 / sk
					end
				end
			end
		end

		if(max_com < $tag_complexity[k])
			max_com = $tag_complexity[k]
		end
		#puts "KKK #{k} complexity is #{$tag_complexity[k]}"
	end
	$remove = []
	$async = []
	dependencies = []
	remove_index = 0
	async_index = 0
	$tag_node.each do |k, v|
		dependencies = v.dup
		k.self_print
		v.each do |node|
			puts "vvv : #{node.getInstr.toString}"
			tdds = traceback_data_dep(node).select{|n| !n.instance_of?Dataflow_edge}
			tdds.each do |tdd|
				next if dependencies.include?tdd
				dependencies << tdd
			end
		end
		
		puts "	dependencies.size = #{dependencies.length}"
		brk = false
		dependencies.each do |node|
			next unless $n_split[node] > 1
			puts "node split 2: #{node.getInstr.toString}"
			brk = true
			break
			
		end
		puts "brk: #{brk}"
		if  $tag_complexity[k] >= 1	 and !brk
			$choices[k] = [] if !$choices[k]
			remove_choice = "remove_#{remove_index}"
		
			if !$choices[k].include?remove_choice
				$choices[k] << remove_choice 
				$remove << [k, v, dependencies]
				puts "found remove opportunity"
				cfs = fix_remove(k,v,dependencies)
				prewrite_code2file(cfs) 
				puts "finish change remove opportunity"
				remove_index += 1
			end
			if $tag_complexity[k] == max_com
				async_choice = "async_#{async_index}"
				if !$choices[k].include?async_choice
					$choices[k] << async_choice
					$async << [k, v, dependencies]
					puts "found async opportunity"
					cfs = fix_async(k,v,dependencies)
					prewrite_code2file(cfs) 
					puts "finish change async opportunity"
					async_index += 1
				end
			end

		end
	end
	$ps = pagination
	$as = approximation
	$choices = $choices.select{|k,v| k}
	puts "  choices = #{$choices.map{|k,v| [k.name, v]}}"
end
def read_log(log_file)
	queries = []
	for l in log_file
		l = l.strip
		#froms,time, table, type, used 
		if l.start_with?('Query Trace')
			fn = l.split(":")[0][/app.*rb/].gsub('app/', '')
			loc = l[/:.*:/].gsub(":", '').to_i
			froms = []
			query = []
			# froms << [fn, loc] unless fn.include?("models/")
			if !fn.include?("models/") and froms.length == 0
				froms << [fn, loc]
			end
			query << froms
			#puts "froms #{froms}"
			next
		end
		if l.start_with?('from')
			fn = l[/app.*rb/].gsub('app/', '') 
			loc = l[/:.*:/].gsub(":", '').to_i
			# froms << [fn, loc] unless fn.include?("models/")
			if !fn.include?("models/") and froms.length == 0
				froms << [fn, loc]
			end
			next
		end
		if l['Load'] or l['COMMIT'] or l['UPDATE'] or l['BEGIN'] or l['SELECT']
			time = l[/\(.*ms\)/]
			if !time
				puts "L is: #{l}"
				next
			end
			tts = l.split(time)[0]
			if tts.strip.split(' ').length == 2
				table = tts.strip.split(' ')[0]
				type = tts.strip.split(' ')[1]
			end
			if l['COMMIT']
				table = ''
				type = 'COMMIT'
			end
			if l['UPDATE']
				table = ''
				type = 'UPDATE'
			end
			if l['BEGIN']
				table = ''
				type = 'BEGIN'
			end
			time = time.gsub('(','').gsub(')','').gsub('ms', '').to_f
			if query
				query << time
				query << table
				query << type
				query << 0
				queries << query
			end
			#puts "QUERY #{query}"
			query = nil
		end
	end
	time_table = {}
	queries.each do |query|
		froms = query[0]
		time = query[1]
		key = froms[-1]
		if time_table[key] 
			time_table[key] += time
		else
			time_table[key]  = time
		end
	end
	time_table.each do |l, t|
		puts "l: #{l} t:#{t}"
	end
	return time_table
end
def compute_performance(output_dir, start_class, start_function, build_node_list_only=false)

	puts "start computing performance #{start_class} #{start_function}"
	# reset the files
	request_file = $of + "request.log"
	choice_filename = $of + "/decisions";
	req_f = open(request_file, 'w')
	req_f.write("FINISH_NO")
	req_f.close
	choice_file = open(choice_filename,'w')
	choice_file.write("")
	choice_file.close

	$start_class = start_class
	preparation(start_class, start_function)
	create_js 
	#return
	$debug = false
	monitor_fix = Thread.new{
		while true
			request = open(request_file).read
			if(request.length > 0)
				next if !request.include?"___"
				alt = request.split("___")[1]
				next if !alt.include?"_"
				alt_type = alt.split("_")[0]
				alt_id = alt.split("_")[1].to_i
				puts "get the request #{alt_type} #{alt_id}" 
				begin
					cfs = []
					if  alt_type == 'pagination'
						parent_instr = $ps[alt_id][0]
						query = $ps[alt_id][1]
						loop_type = $ps[alt_id][2]
						cfs = fix_paginate(parent_instr, query, loop_type)
						key = parent_instr.tag_node#[parent_instr.ln[0], parent_instr.ln[3]]

					elsif alt_type == 'approximation'
						view_node = $as[alt_id][0] 
						query = $as[alt_id][1]
						variable = $as[alt_id][2]
						view_instr = view_node.getInstr
						key = view_instr.tag_node#[view_instr.ln[0], view_instr.ln[3]]
						debug_info(key)
						cfs = fix_approximate(view_node, query,variable)
						
					elsif alt_type == 'async'
						asy = $async[alt_id]
						key = asy[0]
						v = asy[1]
						dependencies = asy[2]
						cfs = fix_async(key, v, dependencies)
						
					elsif alt_type == 'remove'
						rm = $remove[alt_id]
						key = rm[0]
						v = rm[1]
						dependencies = rm[2]
						cfs = fix_remove(key, v, dependencies)
									
					end
					puts "cfs #{cfs}"
					if !cfs or cfs.length == 0
						req_f = open(request_file, 'w')
						req_f.write("FINISH_NO")
						req_f.close
						choice_file = open(choice_filename,'w')
						choice_filename.write("")
						choice_filename.close
					end
					if cfs.length > 0
						prewrite_code2file(cfs) 
						puts "finish prewrite_code2file"
						while(true)
							#puts "choice_filename #{choice_filename}"
							choice_file = open(choice_filename)
							#puts "read"
							cho_con = choice_file.read
							#puts "CHO_con: #{cho_con}"
							if cho_con.include?"YES" or cho_con.include?"NO"
								if cho_con.include?"YES"
									write_code2file(cfs)
									if ['pagination', 'approximation'].include?alt_type	
										update_linenum(key, cfs.map{|x| x[0]}, alt_type)
										$tag_complexity[key] = $tag_complexity[key] - 1
										$tag_complexity_split[key] = $tag_complexity_split[key] - 1
									end	
									if alt_type == 'remove' or alt_type == 'async'
										$tag_complexity.delete(key)
										$tag_complexity_split.delete(key)
									end

												
									$choices.delete(key)
									open(choice_filename,'w').write("")
									
									req_f = open(request_file, 'w')
									req_f.write("FINISH")
									req_f.close
									sleep(1)
									create_js
								else
									req_f = open(request_file, 'w')
									open(choice_filename,'w').write("")
									req_f.write("FINISH_NO")
									req_f.close
								end
								break
							end
						end
					end
				rescue
					puts "Failed refactor"
					open(choice_filename,'w').write("")
					open(request_file, 'w').write("FINISH")
				end
			end
		end
		sleep(1)
	}
	monitor_fix.join
	
end
def create_js
	puts "get into create_js"
	dlog = "#{$of}/log/development.log"
	puts dlog
	time_table = {}
	if File.exists?dlog
		contents = open(dlog).read.lines
		start,start_index = contents.to_enum.with_index.reverse_each.detect{|l,x| l.include?("Processing by #{$start_class}##{$start_function}")}
		if start_index
			
			new_contents = contents[start_index..-1]
			over,over_index = new_contents.each_with_index.detect{|l,x| l.include?("Completed 200 OK")}
			if over_index
				log_file = new_contents[0..over_index]
				puts "start_index #{start_index} to #{over_index}"
				begin
					time_table = read_log(log_file)
					puts "read time_table"
				rescue
					puts "failed to read time_table"
				end
			end
		end
		# if(contents.reverse.detect{|l| l.include?("Completed 200 OK")})
		# 	over = contents.reverse.detect{|l| l.include?("Completed 200 OK")}
		# 	start = contents.reverse.detect{|l| l.include?("Processing by #{$start_class}##{$start_function}")}
		# 	if start
		# 		puts "start: #{start}"
		# 		start_index = contents.rindex(start)
		# 		over_index = contents.rindex(over)
		# 		#puts "from: #{start} to: #{over} #{start_index} #{over_index} #{contents.length}"
		# 		log_file = contents[start_index..over_index]
		# 		time_table = read_log(log_file)
		# 		puts "log_file #{log_file.join}"
		# 	end
		# else
		# 	puts 'nothing is created'
		# 	return
		# end
	end
	time_table.each do |k,v|
		puts "TIMETABLE: k: #{k} v: #{v}"
	end
	cost = {}
	complexity = {}
	$node_list.each do |n|
		next unless  n.getInstr
		re = n.getInstr.getLN
		next unless re
		used_map = {}
		tdds = traceback_data_dep(n).select{|n| !n.instance_of?Dataflow_edge}
		ln_try = n.getInstr.ln
		if ln_try and ln_try[0] != -1
			key = ln_try[0..1]
			puts "keyintime_table #{key} #{n.getInstr.toString} #{n.isQuery?}"
			if !used_map[key] and time_table[key]
				used_map[key] = 1
				cost[n] = time_table[key]
			end
		end
		tdds.each do |tdd|
			#ln_try = getInstrLN(tdd.getInstr)
			ln_try = tdd.getInstr.ln
			if ln_try and ln_try[0] != -1
				key = ln_try[0..1]
				#puts "KEY: #{key} #{tdd.getInstr.getLN} #{tdd.getInstr.toString}"
				if !used_map[key] and time_table[key]
					if cost[n]
						cost[n] += time_table[key]
					else
						cost[n] = time_table[key]
					end
					used_map[key] = 1
				end
			end
		end
	end
	#puts "real-time cost"
	if $of
		js_file_name = $of+"/app/assets/javascripts/interact/interactive.js"
	else
		js_file_name = "./interactive.js"
	end

	output = ""
	output += "  $(document).ready(function(){       
    $('a').click(function(event) {
        event.preventDefault();
    }); 
  	});"
	output += "(function() {\n jQuery(function($) {\n  var choices = [], cost_w = [], cost_r=[], cost_ws = [], cost_rs=[];\n"
	basic = open("interative-basic.js").read

	cost_hash = {}
	cost_split_hash = {}
	cost.each do |n, t|
		#puts "#{n.getInstr.ln} #{t}"
		ln = n.getInstr.ln 
		if ln and ln.length >= 4 and  ln[2] == 1 and ln[3] != 'null' and !ln[3].end_with?"#" and !ln[3].end_with?"%"
			if !cost_hash[ln] 
				cost_hash[ln] = t
			end
			if !cost_split_hash[ln]
				cost_split_hash[ln] = t
				if $n_split[n] 
					sk = $n_split[n]
					cost_split_hash[ln] = t / sk if sk > 1
				end
			end
		end
	end
	output += "  choices = #{$choices.map{|k,v| [k.name, v]}}\n"
	output += "  cost_w = #{cost_hash.group_by{|e,v| e[3]}.map{|k, v| [k.split(" ")[-1], v.map{|ve| ve[1]}.inject{|sum,x| sum}]} }\n"
	output += "  cost_ws = #{cost_split_hash.group_by{|e,v| e[3]}.map{|k, v| [k.split(" ")[-1], v.map{|ve| ve[1]}.inject{|sum,x| sum}]} }\n"
	
	cost_hash.each do |k,v|
		#puts "#{k}: #{v}"
	end
	cr = "  cost_r = #{$tag_complexity.map{|k,v| [k.name, v]}.select{|v| !v[0].start_with?'body' and v[1] >= 0 }.sort_by{|v| v[1]}}\n"
	puts "#{cr}"
	output += cr
	output += "  cost_rs = #{$tag_complexity_split.map{|k,v| [k.name, v]}.select{|v| !v[0].start_with?'body' and v[1] >= 0}.sort_by{|v| v[1]}}\n"
	
	output += basic
	#puts "-------------------"
	output += " });\n}).call(this);\n"
	#puts output
	js_file = open(js_file_name, "w+")
	js_file.write(output)
	#puts output
	puts "......successfully create interactive.js......"
	js_file.close
	
end
def extractClosuresParentNode
	closures = []
	$node_list.each do |n|
		if n.getInClosure
			if n.getClosureStack.length > 0
					closures |= n.getClosureStack
			end
		end
	end	
	return closures
end
def construct(sliced)
	codes = []
	closures = []
	branches = []
	cur_closure = nil
	cur_branch = nil
	outgoings = []
	cur_instructions = []
	cur_cfg = nil
	set_else = true
	set_end = true
	all_closures = extractClosuresParentNode
	pushed = false
	sliced = sliced.select{|s| !s.instance_of?Dataflow_edge and s.getInstr }
	sliced = sliced.sort_by{|s| [s.getInstr.getBB, s.getInstr.getIndex]}
	sliced.each do |s|
		puts "s #{s.getInstr.toString}"
		instr = s.getInstr
		code = instr.toCode
		pushed = false
		if instr.getClosure and instr.getClosure.parent_instr == instr
			closures.push(s)
			cur_closure = s
			cur_instructions = instr.getClosure.getAllInstrs
			codes.push(code)
			pushed = true
			#next
		end
		if instr.instance_of?Branch_instr
			branches.push(instr)
			cur_branch = instr
			cur_cfg = instr.getBB.getCFG
			outgoings = instr.getBB.getOutgoings
			set_else = true
			puts "outgoings #{outgoings}"
		end
		if cur_branch and instr.getBB == cur_cfg.getBBByIndex(outgoings[1]) and set_else
			codes.push("else")
			puts "instr is : #{instr.toString}"
			set_else = false
		end
		if cur_branch and instr.getBB == cur_branch.merge_instr.getBB and set_end
			codes.push("end")
			puts 'branch put end'
			branches.pop
			if branches.length > 0
				cur_branch = branches[-1]
				cur_cfg = cur_branch.getBB.getCFG
				outgoings = cur_branch.getBB.getOutgoings
				set_else = true
				set_end = true
			else
				cur_branch = nil
				cur_cfg = nil
				outgoings = []
				set_else = true
				set_end = false
			end
		end
		if cur_instructions.length > 0 
		 	if cur_instructions.include?instr 
		 	elsif instr == cur_closure.getInstr
			else
				codes.push("end")
				closures.pop
				if closures.length > 0
					cur_closure = closures[-1] 
					cur_instructions = cur_closure.getInstr.getClosure.getAllInstrs
				else
					cur_closure = nil
					cur_instructions = []
				end
				puts 'put to the end'
				cur_instructions = []
			end
		end
		if pushed == false
			codes.push(code) 
			puts code
		end
		
	end
	while(closures.length > 0)
		codes.push("end")
		closures.pop
	end
	while(branches.length > 0)
		codes.push("end")
		branches.pop
	end
	#puts "----------------------"
	vars = Array.new
	values = Array.new
	codes.each do |code|
		if code
			vv = code.split(" = ")
			if vv.length == 2
				vars.push(vv[0])
				values.push(vv[1])
			else
				vars.push("")
				values.push(code)
			end
		end
	end
	used = Array.new(values.length) { |i|  i = 0}
	for i in 0..vars.length-1
		var_i = vars[i]
		value_i = values[i]
		for j in (i+1)..vars.length-1
			var_j = vars[j]
			value_j = values[j]
			if var_i.start_with?('%') and value_j.include?var_i
				a = value_j.gsub(var_i.strip, value_i.strip)
				values[j] = a
				used[i] = 1
			end
		end
	end
	output = ""
	for i in 0..vars.length-1
		if used[i] == 0
			if vars[i].start_with?('%') and !vars[i].start_with?('%self')
				output = output +  values[i] + "\n"
			elsif vars[i] == "" 
				output = output + values[i] + "\n" unless values[i] == ""
			else
				output = output + "#{vars[i]} = #{values[i]}" + "\n"
			end
		end
	end	
	output = output.gsub("\%self.", "@")
	puts "output\n#{output}"
	puts "--------Finished--------"
	return output
end
def slicing(ns)
	nodes = Array.new
	used_nodes = Array.new
	ns.each do |n|
		used_nodes.push(n)
		nodes.push(n)
	end
	while(nodes.length > 0)
		node = nodes.pop
		if node.instance_of?Dataflow_edge
			next
		end
		puts node.getInstr.toString
		deps = traceback_data_dep(node)
		deps.each do |dep|
			if !nodes.include?dep
				nodes.push(dep)
			end
			if !used_nodes.include?dep
				used_nodes.push(dep)
			end
		end
		if node.getInClosure
			node.getNonViewClosureStack.each do |cl|
				parent_node = cl
				if !nodes.include?parent_node
					nodes.push(parent_node)
				end
				if !used_nodes.include?parent_node
					used_nodes.push(parent_node)
				end
			end
		end
		node.getInstr.getBB.getInstr[0].getINode.getBackwardControlEdges.each do |e|
			fromn = e.getFromNode
			if fromn.getInstr and fromn.getInstr.instance_of?Branch_instr
				if !nodes.include?fromn
					nodes.push(fromn)
				end
				if !used_nodes.include?fromn
					used_nodes.push(fromn)
				end				
			end
		end

	end
	return used_nodes

end

def whole_unused
	nodes = Array.new
	$node_list.each do |n|
		if n.instance_of?Dataflow_edge
			next
		end
		ln = getInstrLN(n.getInstr)
		if ln.length == 3 and ln[2] == 1
			nodes.push(n)
		elsif n.getInstr.instance_of?Call_instr 
			if n.getInstr.getFuncname == 'render'
				nodes.push(n)	unless nodes.include?n
			elsif $view_helpers.include?n.getInstr.getFuncname
				nodes.push(n)	unless nodes.include?n
			end
		end
	end
	used_nodes = slicing(nodes)
	puts used_nodes.length 
	puts $node_list.length
	puts "+++++++++++++++++++++++++++"
	unused_nodes = $node_list - used_nodes
	puts unused_nodes.length
	final_nodes = unused_nodes.select{|n| n.getInstr.getDeps.length != 0}
	puts final_nodes.length
	unused_nodes.each do |n|
		if n.instance_of?Dataflow_edge
			next
		end
		ln = getInstrLN(n.getInstr)
		if n.getInstr.getDeps.length != 0
			puts "#{n.getInstr.toString} #{n.getInstr.class} #{n.getInstr.getDefv} #{ln[0]} #{ln[1]}"
		end
	end
	return unused_nodes
end

def pagination
	loop_type = 'each'
	@closures = Array.new
	$node_list.each do |n|
			instr = n.getInstr
			if instr and instr.ln and instr.ln[2] and instr.ln[2] != -1 and n.getInClosure
				if n.getNonViewClosureStack.length > 0
						@closures |= n.getNonViewClosureStack
				end
			end
	end
	results = []
	@closures.each do |cl|
		@cl_nodes = Array.new
		query = nil
		if !cl.getInstr or !cl.getInstr.getClosure
			next
		end

		begin
			#puts "ppppp #{cl} "
			#puts "ppppp #{cl.getInstr} #{cl.getInstr.toString} #{cl.getInstr.ln}"	
			parent_instr = cl.getInstr
			puts "	#{cl.getInstr.ln}"	
			nt = false
			funcname = parent_instr.getFuncname
			if (parent_instr.instance_of?Call_instr and funcname.include?'each' or funcname.include?'map')	
				#nt = true
				loop_type = funcname
				puts "loop #{parent_instr.toString} set loop_type: #{loop_type}"
				puts "parent_instr.getcaller : #{parent_instr.getCaller}"
				q = check_parent_instr_query(cl, parent_instr.getCaller)
				if !q
					next
				end
				puts "card_limited #{q.card_limited}"
				#puts "parent_instr_is: #{parent_instr_is_query}"
				if !q.card_limited
					nt = true
					puts "set nt to be true"
					query = q
					puts "Q: #{q.getInstr.toString} #{q.isQuery?} #{q.card_limited} #{q.getInstr.ln}" # if q and q.getInstr
					cl.is_unbounded_loop = true
					puts "set unbouded"
				end
			else
				next
			end
			# qs = traceback_data_dep(cl).select{|x| !x.instance_of?Dataflow_edge}
			# puts "qs.length: #{qs.length}"
			# qs.each do |q|
			# 	if q and q.getInstr and q.getInstr.instance_of?Call_instr and ['group_by', 'sort_by'].include?q.getInstr.getFuncname
			# 		nt = false
			# 		puts "group_by funcname: #{q.getInstr.getFuncname} #{q.getInstr.toString}"
			# 		break
			# 	end
			# 	puts "q.instr.toString #{q.getInstr.toString}  #{q.isQuery?}"
			# 	if q.isQuery? and !q.card_limited
			# 		nt = true
			# 		puts "set nt to be true"
			# 		query = q
			# 		puts "Q: #{q.getInstr.toString} #{q.isQuery?} #{q.card_limited} #{q.getInstr.ln}" # if q and q.getInstr
			# 		cl.is_unbounded_loop = true
			# 		puts "set unbouded"
			# 		break
			# 	end

			# end
			if !nt
				puts "jump out paginate"
				next
			else
				puts "not out"
				puts "parent_instr: #{parent_instr.toString} #{parent_instr.ln} "
				puts "#{query.getInstr.toString}"
				puts "tag_Node: #{parent_instr.tag_node} set2 loop_type: #{loop_type}"
				results << [parent_instr, query, loop_type] if parent_instr.ln[3] and parent_instr.tag_node
			end
		rescue
			puts "rescue from"
		end
	end
	for i in 0...results.length
		result = results[i]
		k = result[0]
		v = result[1]
		loop_type = result[2]
		if !k.ln[3]
			next
		end
		if !$choices[k.tag_node]
			$choices[k.tag_node] = []
		end
		$choices[k.tag_node] << "pagination_#{i}" unless $choices[k.tag_node].include?"pagination_#{i}"
		cfs = fix_paginate(k, v, loop_type)
		#prewrite_code2file(cfs)
	end
	return results
end
def approximation
	c_v = []
	# $node_list.each do |n| 
	# 	if !n.instance_of?Dataflow_edge 
	# 		tdds = traceback_data_dep(n).select{|x| !x.instance_of?Dataflow_edge}
	# 		tdds.each do |tdd|
	# 			if tdd.isQuery? 
	# 				puts "query 1: #{tdd.getInstr.toString}"
	# 				if ['count', 'maximum', 'minimum', 'sum', 'calculate'].include?tdd.getInstr.getFuncname 
	# 					puts "query function #{tdd.getInstr.toString}"
	# 				end
	# 			end
	# 		end
	# 	end
	# end
	i = 0

	$node_list.each do |n| 
		tmp_v = []
		if !n.instance_of?Dataflow_edge and n.isQuery? and !n.card_limited
			if ['count', 'maximum', 'minimum', 'sum', 'calculate'].include?n.getInstr.getFuncname 
				query_var = n.getInstr.getDefv
				puts "aggregate query: #{n.getInstr.toString} #{query_var}"
				nln = n.getInstr.ln
				if nln and nln.length >= 4
					key = n.getInstr.tag_node
					if nln[2] == 1 and tmp_v.length == 0
						tmp_v << [n, n, nil] unless tmp_v.include?([n,n,nil])
					end
				end
				fds = traceforward_data_dep(n).select{|x| !x.instance_of?Dataflow_edge}
				assign_node = nil
				variable = nil
				fds.each do |fd|
					fln = fd.getInstr.ln
					next unless fln
					fd_instr = fd.getInstr
					if fd_instr.instance_of?Copy_instr and  fd_instr.type == 'PASS'
						#puts "copy instruction #{fd_instr.getDefv}"
						copy_var = fd_instr.getDeps[0].getVname
						defv = fd_instr.getDefv
						if copy_var == query_var and !defv.start_with?"%"
							assign_node = fd
							variable = defv
							puts "copy instruction #{defv}"
						end
					elsif fd_instr.instance_of?AttrAssign_instr
						defv = "#{fd_instr.getCaller}.#{fd_instr.getFuncname}"
						assign_var = fd_instr.getDeps[0].getVname
						if assign_var == query_var and defv.start_with?"%self"
							assign_node = fd
							variable = defv.gsub("%self",'@')
							puts "assign instruction #{defv}"
						end
					end
				end
				if assign_node
					fds = traceforward_data_dep(assign_node).select{|x| !x.instance_of?Dataflow_edge}
				end
				fds.each do |fd|
					if !fd.instance_of?Dataflow_edge 
						fln = fd.getInstr.ln
						next unless fln
						puts "\t nln #{nln} #{fd.getInstr.toString}"
						
						if fln[2] == 1 and fln.length >= 4
							key = fd.getInstr.tag_node
							puts "key: #{key}"
							if tmp_v.length == 0
								tmp_v << [fd, n, variable]  unless tmp_v.include?([fd,n,variable])
							end
							if traceforward_data_dep(fd).select{|x| !x.instance_of?Dataflow_edge and x.getInstr.ln[0..1] != fln[0..1]}.length > 0
								tmp_v = []
								puts "break because the view node has other dependencies"
								break
							end
						elsif fln[2] == 0 and fln[0..1] != nln[0..1] 
							tmp_v = []
							puts "break because there are instructions are on the another line"
							break
						end
					end
				end
			end
		end
		c_v += tmp_v.dup
	end
	for i in 0...c_v.length
		view_node = c_v[i][0]
		query_node = c_v[i][1]
		variable = c_v[i][2]
		key = view_node.getInstr.tag_node
		$choices[key] = [] unless $choices[key]
		$choices[key] << "approximation_#{i}" 
		cfs = fix_approximate(view_node, query_node, variable)
		#prewrite_code2file(cfs)
	end
	return c_v
end
def computeCom(queryNode)
	if queryNode and !queryNode.instance_of?Dataflow_edge and queryNode.isQuery?
		com = 0
		deps  = traceback_data_dep(queryNode)
		deps.delete(queryNode)
		puts "deps.length: #{deps.length} #{queryNode.getInstr.toString}"
		deps.each do |fd| 
			if !fd.instance_of?Dataflow_edge and fd.isQuery?
				tmp = computeCom(fd)
				puts "tmp #{tmp}"
				#puts "fd: #{fd.getInstr.toString} \ncomplexity: #{tmp}]\n"
				if tmp > com
					com = tmp
				end
			end
			#puts "++++++++++"
		end
		query_ins = queryNode.getInstr
		funcname = query_ins.getFuncname
		if(['paginate', 'limit','find','find_by'].include?funcname)
			# puts "com is :#{queryNode.getInstr.toString} #{com}"
			# puts "============="
			return com
		elsif ['where'].include?funcname
			puts "query_ins.getArgs #{query_ins.getArgs}"
			args = query_ins.getArgs
			if args.length > 1 and query_ins.getBB.getCFG.getVarMap[args[0]].type =='string'
				return com + args.length - 1
			end
			return com + args.length
		elsif ['joins'].include?funcname
			return com + 2
		elsif ['order'].include?funcname
			args = query_ins.getArgs
			syms = query_ins.symbols
			puts "sysms #{syms}"
			syms.each do |arg|
				puts "sym: #{arg} #{query_ins.getCallerType} testTableIndex : #{testTableIndex(query_ins.getCallerType, arg)}"
				com += 1 if !testTableIndex(query_ins.getCallerType, arg)
			end
			args.each do |arg|
				puts "arg: #{arg} #{query_ins.getCallerType} testTableIndex : #{testTableIndex(query_ins.getCallerType, arg)}"
				next if arg == 'Symbol'
				next if testTableIndex(query_ins.getCallerType, arg)
				com += 1
			end
			return com
		else
			# puts "com is :#{queryNode.getInstr.toString} #{com}"
			# puts "============="
			return com + 1
		end
	else
		return 0
	end
end
def computeComplexity
	$n_c  = {}
	$n_split = {}
	i = 0
	$node_list.each do |n| 
		puts "i #{i}"
		i += 1
		if !n.instance_of?Dataflow_edge and n.isQuery?
			puts "query"
			loops = n.getUnboundedNonViewClosureStack.length
			puts "loops: #{loops}"	
			$n_c[n] = computeCom(n) + loops
			puts "n_c[n]: #{n.getInstr.toString} #{$n_c[n]}"
		end
		if !n.instance_of?Dataflow_edge
			tags = []

			forward_nodes = traceforward_data_dep(n)
			puts "++++Node is: #{n.getInstr.toString} #{forward_nodes.length}"
			nln = n.getInstr.ln
			#puts "nln: #{nln}"
			if nln and nln.length >= 4 and nln[3] and nln[3] != 'null' and nln[3] != nil
				key = [nln[0], nln[3]]
				tags << key
				#puts "-add key #{key}"
			end
			forward_nodes.each do |tdd|
				if !tdd.instance_of?Dataflow_edge
					nln = tdd.getInstr.ln
					#puts "-nln  #{nln}"
					if !nln or nln.length < 4 or !nln[3] or nln[3] == 'null'
						next
					end
					key = [nln[0], nln[3]]
					if !tags.include?key
						tags << key 
						#puts "+add key #{key}"
					end
				end
			end
			$n_split[n] = tags.length
			puts "splits: #{n.getInstr.toString} #{$n_split[n]}" if $n_split[n]>0
		end
	end
	# $n_c.each do |k, v|
	# 	puts "k: #{k.getInstr.toString} \n#{k.getInstr.ln} complexity: #{v} \n"
	# end
end
def prewrite_code2file(code_file_snippets)
	filename = $of + "finish.flag"
	f = open(filename, 'w')
	puts "Length: #{code_file_snippets.length}"
	code_file_snippets.each do |k, v|
		begin
			ori_file = k
			if !File.exists?k
				new_file = open('tmp1', 'w')
				new_file.close
				ori_file = 'tmp1'
			end
			tmp_f = open('tmp', 'w')
			tmp_f.write(v.join)
			tmp_f.close
			diff = `diff #{ori_file} tmp`
			f.write(k)
			f.write("\n")
			puts "filename: #{k}"
			puts diff
			f.write(diff)
		rescue
			puts "fail write diff #{k}"
		end
	end
	puts "write1"
	File.delete('tmp') if File.exists?'tmp'
	File.delete('tmp1') if File.exists?'tmp1'
	f.write("===Above are changed files and how they will look like====")
	f.close
	puts "prewrite_code2file function finish"
end
def write_code2file(code_file_snippets)
	puts "write_code2file"
	code_file_snippets.each do |k, v|
		if !$debug
		  tf = open(k, 'w')
		  tf.write("#{v.join}")
		  tf.close
		end
		puts "#{k}\n#{v.join}"
	end
	puts "-----finish write_code2file ---- "
end

def update_linenum(tag, files, type)
	sl = tag.start_line 
	el = tag.end_line
	puts "sl: #{sl} el: #{el} files: #{files.length}"
	nodes = $node_list.select{|n| !n.instance_of?Dataflow_edge and n.getInstr and n.getInstr.ln and n.getInstr.ln[0] and n.getInstr.ln[0] == tag.filename}
	if type == 'pagination'
		if files.length == 2
			# query and objects different file	
			$tags.each do |k, t|
				puts "#{t.start_line} #{t.end_line}"
				if  t.start_line > el
					t.start_line += 1
				end
				if t.end_line > el
					t.end_line += 1
				end
			end	
			
			nodes.each do |n|
				instr = n.getInstr
				if instr.ln[1] > el
					instr.ln[1] += 1
				end
			end
			
		elsif files.length == 1
			# objects same files
			$tags.each do |k, t|
				if t.start_line >= sl and t.start_line <= el
					t.start_line += 1
				elsif t.start_line > el
					t.start_line += 2
				end
				if t.end_line >= sl and t.end_line <= el
					t.end_line += 1
				elsif t.end_line > el
					t.end_line += 2
				end
			end
			nodes.each do |n|
				instr = n.getInstr
				if instr.ln[1] >= sl and instr.ln[1] <= el
					instr.ln[1] += 1
				elsif instr.ln[1] > el
					instr.ln[1] += 2
				end
			end
		end
	elsif type == 'approximation'
		# larger than loc of tag start needs to increase 1		
		$tags.each do |k, t|
			puts "start_line"
			if  t.start_line >= sl
				puts "before #{t.toString}"
				t.start_line += 1
				puts "after #{t.toString}"
			end
			puts "end_line"
			if t.end_line >= sl
				puts "before #{t.toString}"
				t.end_line += 1
				puts "after #{t.toString}"
			end
		end	
		puts "updated tags"
		nodes.each do |n|
			instr = n.getInstr
			if instr.ln[1] >= sl
				instr.ln[1] += 1
			end
		end
	end
	puts "finished updating line num"
end

def check_parent_instr_query(cl, var)
	if var == ""
		return nil
	end
	begin
		qs = traceback_data_dep(cl).select{|x| !x.instance_of?Dataflow_edge}
		#qs = qs.delete(cl)
		puts "qs.length : #{qs.length}"
		qs.each do |dq|
			d_instr = dq.getInstr
			next if !d_instr
			puts "START: #{d_instr.toString}"
			if d_instr.instance_of?ReceiveArg_instr
				next
			end
			if d_instr.instance_of?AttrAssign_instr
				def_var = "#{d_instr.getCaller}.#{d_instr.getFuncname}"
				puts "1: #{d_instr.toString} #{def_var} isQuery: #{dq.isQuery?}"
				if def_var = var
					return dq if dq.isQuery?
					if d_instr.getDeps and d_instr.getDeps.length > 0
						new_var = d_instr.getDeps[0].getVname
						return check_parent_instr_query(dq, new_var)
					end
				end
			elsif d_instr.instance_of?Copy_instr and d_instr.type == 'PASS'
				def_var = d_instr.getDefv
				puts "2: #{d_instr.toString} #{def_var}"
				if def_var = var
					return dq if dq.isQuery?
					new_var = d_instr.getDeps[0].getVname
					return check_parent_instr_query(dq, new_var)
				end
			elsif d_instr.instance_of?GetField_instr
				def_var = d_instr.getDefv
				puts "3: #{d_instr.toString} #{def_var}"
				if def_var == var
					return dq if dq.isQuery?
					new_var = "#{d_instr.getCaller}.#{d_instr.getFuncname}"
					return check_parent_instr_query(dq, new_var)
				end
			elsif d_instr and d_instr.getDefv
				def_var = d_instr.getDefv
				puts "4: #{d_instr.toString} #{def_var} #{var}"
				if d_instr.getDefv == var
					puts "here"
					puts "dq.isQuery #{dq.isQuery?} #{d_instr.class.name}"
					return dq if dq.isQuery?
					if d_instr.instance_of?Call_instr
						puts "callertype #{d_instr.getCallerType}"
						funcname = d_instr.getFuncname
						if(['to_a','sort_by', 'select'].include?funcname)
							new_var = d_instr.getCaller
							return  check_parent_instr_query(dq, new_var)
						else
							dqqs = traceback_data_dep(dq).select{|x| !x.instance_of?Dataflow_edge}
							dqqs.each do |x|
								puts "xxxx: #{x.getInstr.toString} #{x.getInstr.class.name} #{x.instance_of?Return_instr}"
								x_instr = x.getInstr
								if x_instr.instance_of?Return_instr
									new_var = x_instr.getDeps[0].getVname
									puts "new_var in return is: #{new_var}"
									return check_parent_instr_query(dq, new_var)
								end
							end
							return nil
						end
					end
				end
			end
		end
		
		return nil
	rescue
		puts "rescue from check_parent_instr_query"
		return nil
	end
end
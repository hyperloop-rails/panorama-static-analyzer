require 'pathname'
require 'yard'
require 'work_queue'
apppath = "#{ARGV[0]}"
non_dirs = ['controllers']
load '../controller_model_analysis/traverse_ast.rb'
def os_walk(dir)
  root = Pathname(dir)
  files, dirs = [], []
  Pathname(root).find do |path|
    unless path == root
      dirs << path if path.directory?
      files << path if path.file?
    end
  end
  return root, files, dirs
end
def generate_dataflow(apppath, c_a)
	wq = WorkQueue.new 10, 20
	time1 = Time.now
	#puts"APPPATH #{apppath}"
	root, files, dirs = os_walk(apppath)
	threads = []
	if c_a
		fn = c_a.split(',')[0]
		fs = fn.gsub("::", "/").gsub(/\w(?=[A-Z])/){|match| "#{match}_"}.gsub("Controller", "controller").downcase
		filename = apppath + '/dataflow/merged_controllers/'  + fs + ".log"
		cfilename = apppath + '/merged_controllers/'  + fs + '.rb'
		contents = open(cfilename, 'r').read
		root = YARD::Parser::Ruby::RubyParser.parse(contents).root
		root = getDefNode(root, c_a.split(',')[1])
		$const = [fn]
		con(root)
		$const_fn = $const.map{|e| e.gsub("::", "/").gsub(/\w(?=[A-Z])/){|match| "#{match}_"}.gsub("Controller", "controller").downcase}

	end
	files.each do |filename|
		#puts"filename #{filename}"
		wq.enqueue_b("") do
        
				time = Time.now
				if filename.to_s.end_with?(".rb")
				fname = filename.to_s
				n_begin = filename.to_s.rindex('/')
				n_end = filename.to_s.rindex('.')
				class_name = filename.to_s[n_begin+1...n_end]
				if $const_fn and !$const_fn.include?class_name
					next
				end
				#puts"classname #{class_name} #{fname}"
				if class_name == "schema"
					next
				end
				k = fname.index("#{apppath}")
				#des_file = "%s/%s.log"%(des_controller,class_name)
				l = fname.index(".rb")
				if !l
					next
				end
				#puts"fname: #{fname} k: #{k} l: #{l} #{}"
				des_file = fname[0...k+apppath.length] + "/dataflow/" + fname[k+apppath.length...l] + ".log"
				d_ind = des_file.rindex('/')
				dir_name = des_file[0...d_ind+1]
				if dir_name.include?"/controllers"
					next
				end
				#puts"dir_name = #{dir_name}"
				if File.exist?(dir_name) == false
					system("mkdir -p #{dir_name}")
				end
				cmd = "jrubyc #{fname} > #{des_file}"
				puts cmd
				system(cmd)
				system("rm #{fname.gsub(".rb",".class")}")
			
			#thread.join
			#puts"DURATION: #{Time.now - time}"
			end
		end
		#}
		#threads.push(thread)
			#thread.join
	end
	wq.join
	# threads.each do |t|
	# 	t.join
	# end
end
generate_dataflow(ARGV[0], ARGV[1])
#puts"JRUBY: #{Time.now - time1}"
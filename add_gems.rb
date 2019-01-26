folder = ARGV[0]
gems = ['will_paginate', 'bootstrap-sass', 'sass-rails', 'render_async', 'react-rails-hot-loader', 'active_record_query_trace']
re_gems = []
for gem in gems 
  has_gem_cmd = `cd #{folder}; bundle show #{gem}`
  if has_gem_cmd.include?"Could not find gem '#{gem}'"
   re_gems << gem
   #puts "has #{has_gem_cmd}"
  end
end
puts re_gems
success_msg = "Bundle complete!"
gemfilename = folder + "/" + 'Gemfile'
if File.exists?gemfilename
  gemfile = open(gemfilename, 'a')
  original_file = open(gemfilename,'r').read
  re_gems.each do |gem|
    add_gem_string = "gem '#{gem}'\n"
    gemfile.write(add_gem_string)
  end
  gemfile.close
  # run bundle install
  bundle_msg = `cd #{folder}; bundle install`
  
  # if not successful, output the error msg and restore the Gemfile
  if !bundle_msg.include?success_msg
    open(gemfilename,'w').write(original_file)
    puts "====gem file add error====\ndetailed reasons are listed:"
    puts bundle_msg
  end
else
  puts "Gemfile doesn't exist"
end


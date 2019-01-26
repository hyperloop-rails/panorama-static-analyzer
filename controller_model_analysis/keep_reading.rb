request_file = "request"
while(true)
	if File.exists?request_file
		f = open(request_file, "r")
		puts f.read
		system("rm #{request_file}")
	end
	sleep(5)
end


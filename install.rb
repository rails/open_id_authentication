puts "Creating tmp/openids..."
tmp_path = RAILS_ROOT + "/tmp/openids"
Dir.mkdir(tmp_path) unless File.exist?(tmp_path)
puts "This directory should be hosted on a shared drive for all application servers"
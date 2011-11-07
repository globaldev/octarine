libs = %W{app endpoint path path_template request response}
libs.map {|lib| File.expand_path("../octarine/#{lib}", __FILE__)}.each do |lib|
  require lib
end

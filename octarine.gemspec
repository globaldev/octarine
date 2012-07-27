Gem::Specification.new do |s|
  s.name = "octarine"
  s.version = "0.0.3"
  s.summary = "HTTP routing proxy DSL"
  s.description = "Sinatra-like DSL for writing a HTTP routing proxy."
  s.files = %W{lib}.map {|dir| Dir["#{dir}/**/*.rb"]}.flatten << "README.rdoc"
  s.require_path = "lib"
  s.rdoc_options = ["--main", "README.rdoc", "--charset", "utf-8"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.author = "Matthew Sadler"
  s.email = "mat@sourcetagsandcodes.com"
  s.homepage = "http://github.com/globaldev/octarine"
  s.add_dependency("http_router")
end

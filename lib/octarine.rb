libs = %W{app endpoint path request response}.map(&"../octarine/".method(:+))
libs.map {|lib| File.expand_path(lib, __FILE__)}.each(&method(:require))

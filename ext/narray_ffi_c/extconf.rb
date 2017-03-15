require 'mkmf'
require 'rbconfig'

if RUBY_VERSION < "1.9" then
  conf = Config::CONFIG
else
  conf = RbConfig::CONFIG
end

dir_config("narray", conf["archdir"])

unless have_header("narray.h")
  begin
    require "rubygems"
    if spec = Gem::Specification.find_all_by_name("narray").last then
      path = spec.require_path
      if not File.exist?( path+"/narray.h") then
        path = spec.full_gem_path
      end
      $CPPFLAGS = "-I" << path << "/ " << $CPPFLAGS
      if /cygwin|mingw/ =~ RUBY_PLATFORM then
        $LDFLAGS = "-L" << path << "/" << $LDFLAGS
      end
    end
  rescue LoadError
  end
  unless have_header("narray.h")
    abort "missing narray.h" unless have_header("narray.h")
  end
end

if /cygwin|mingw/ =~ RUBY_PLATFORM then
  $LDFLAGS = "-l:narray.so " << $LDFLAGS
end

create_makefile("narray_ffi_c")

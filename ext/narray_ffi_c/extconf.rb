require 'mkmf'
require 'rbconfig'

if RUBY_VERSION < "1.9" then
  conf = Config::CONFIG
else
  conf = RbConfig::CONFIG
end

dir_config("narray", conf["archdir"])

if /cygwin|mingw/ =~ RUBY_PLATFORM then
  $LDFLAGS = "libnarray.a " << $LDFLAGS
end

unless have_header("narray.h")
  begin
    require "rubygems"
    if spec = Gem::Specification.find_all_by_name("narray").last then
      spec.require_paths.each { |path|
        $CPPFLAGS = "-I" << spec.full_gem_path << "/" << path << "/ " << $CPPFLAGS
        if /cygwin|mingw/ =~ RUBY_PLATFORM then
          $LDFLAGS = "-L" << spec.full_gem_path << "/" << path << "/ " << $LDFLAGS
        end
      }
    end
  rescue LoadError
  end
  unless have_header("narray.h")
    abort "missing narray.h" unless have_header("narray.h")
  end
end

create_makefile("narray_ffi_c")

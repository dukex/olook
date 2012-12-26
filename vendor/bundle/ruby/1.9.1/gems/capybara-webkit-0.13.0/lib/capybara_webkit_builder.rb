require "fileutils"
require "rbconfig"

module CapybaraWebkitBuilder
  extend self

  SUCCESS_STATUS = 0
  COMMAND_NOT_FOUND_STATUS = 127

  def make_bin
    ENV['MAKE'] || 'make'
  end

  def qmake_bin
    ENV['QMAKE'] || 'qmake'
  end

  def spec
    ENV['SPEC'] || os_spec
  end

  def os_spec
    case RbConfig::CONFIG['host_os']
    when /linux/
      "linux-g++"
    when /freebsd/
      "freebsd-g++"
    when /mingw32/
      "win32-g++"
    else
      "macx-g++"
    end
  end

  def sh(command)
    system(command)
    success = $?.exitstatus == SUCCESS_STATUS
    if $?.exitstatus == COMMAND_NOT_FOUND_STATUS
      puts "Command '#{command}' not available"
    elsif !success
      puts "Command '#{command}' failed"
    end
    success
  end

  def makefile
    sh("#{qmake_bin} -spec #{spec}")
  end

  def qmake
    sh("#{make_bin} qmake")
  end

  def path_to_binary
    case RUBY_PLATFORM
    when /mingw32/
      "src/debug/webkit_server.exe"
    else
      "src/webkit_server"
    end
  end

  def build
    sh(make_bin) or return false

    FileUtils.mkdir("bin") unless File.directory?("bin")
    FileUtils.cp(path_to_binary, "bin", :preserve => true)
  end

  def clean
    File.open("Makefile", "w") do |file|
      file.print "all:\n\t@echo ok\ninstall:\n\t@echo ok"
    end
  end

  def build_all
    makefile &&
    qmake &&
    build &&
    clean
  end
end

require 'rbconfig'

module GVUtils
  # Since this code is an adaptation of Launchy::Application#find_executable
  # (http://copiousfreetime.rubyforge.org/launchy/Launchy/Application.html)
  # it follow is licence :
  #
  # Permission to use, copy, modify, and/or distribute this software for any
  # purpose with or without fee is hereby granted, provided that the above
  # copyright notice and this permission notice appear in all copies.
  #
  # THE SOFTWARE IS PROVIDED AS IS AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  # WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  # MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
  # SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  # WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
  # OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
  # CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  def find_executable(bin, custom_paths) #:nodoc:
    system_path = ENV['PATH']
    user_given_path = Array(custom_paths).join(File::PATH_SEPARATOR)
    search_path = system_path + File::PATH_SEPARATOR + user_given_path

    search_path.split(File::PATH_SEPARATOR).each do |path|
      file_path = File.join(path,bin)
      return file_path if File.executable?(file_path) and File.file?(file_path)

      if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ # WAS: elsif RUBY_PLATFORM =~ /mswin|mingw/
        found_ext = (ENV['PATHEXT'] || '.exe;.bat;.com').split(";").find {|ext| File.executable?(file_path + ext) }
        return file_path + found_ext if found_ext
      end
    end
    return nil
  end

  def escape_path_containing_blanks(path) #:nodoc:
    path.gsub!(File::ALT_SEPARATOR, File::SEPARATOR) if File::ALT_SEPARATOR
    path_elements = path.split(File::SEPARATOR)
    path_elements.map! do |element|
      if element.include?(' ')
        "\"#{element}\""
      else
        element
      end
    end
    path_elements.join(File::SEPARATOR)
  end

  def output_and_errors_from_command(cmd) #:nodoc:
   unless defined? Open3
     begin
       require 'open3'
       require 'win32/open3'
     rescue LoadError
     end
   end
   begin
     Open3.popen3( cmd ) do |stdin, stdout, stderr|
       stdin.close
       stdout.binmode
       [stdout.read, stderr.read]
     end
   rescue NotImplementedError, NoMethodError
     IO.popen( cmd ) do |stdout|
       stdout.binmode
       [stdout.read, nil]
     end
   end
  end

  def output_from_command(cmd) #:nodoc:
   output, errors = output_and_errors_from_command(cmd)
   if errors.nil? || errors.strip.empty?
     output
   else
     raise "Error from #{cmd}:\n#{errors}"
   end
  end

end

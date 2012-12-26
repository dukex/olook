require 'rack/protection'

module Rack
  module Protection
    ##
    # Prevented attack::   Non-permanent XSS
    # Supported browsers:: Internet Explorer 8 and later
    # More infos::         http://blogs.msdn.com/b/ie/archive/2008/07/01/ie8-security-part-iv-the-xss-filter.aspx
    #
    # Sets X-XSS-Protection header to tell the browser to block attacks.
    #
    # Options:
    # xss_mode:: How the browser should prevent the attack (default: :block)
    class XSSHeader < Base
      default_options :xss_mode => :block

      def header
        { 'X-XSS-Protection' => "1; mode=#{options[:xss_mode]}" }
      end

      def call(env)
        status, headers, body = @app.call(env)
        [status, header.merge(headers), body]
      end
    end
  end
end

# -*- encoding: binary -*-
require 'logger'

# Implements a simple DSL for configuring a \Unicorn server.
#
# See http://unicorn.bogomips.org/examples/unicorn.conf.rb and
# http://unicorn.bogomips.org/examples/unicorn.conf.minimal.rb
# example configuration files.  An example config file for use with
# nginx is also available at
# http://unicorn.bogomips.org/examples/nginx.conf
#
# See the link:/TUNING.html document for more information on tuning unicorn.
class Unicorn::Configurator
  include Unicorn

  # :stopdoc:
  attr_accessor :set, :config_file, :after_reload

  # used to stash stuff for deferred processing of cli options in
  # config.ru after "working_directory" is bound.  Do not rely on
  # this being around later on...
  RACKUP = {
    :daemonize => false,
    :host => Unicorn::Const::DEFAULT_HOST,
    :port => Unicorn::Const::DEFAULT_PORT,
    :set_listener => false,
    :options => { :listeners => [] }
  }

  # Default settings for Unicorn
  DEFAULTS = {
    :timeout => 60,
    :logger => Logger.new($stderr),
    :worker_processes => 1,
    :after_fork => lambda { |server, worker|
        server.logger.info("worker=#{worker.nr} spawned pid=#{$$}")
      },
    :before_fork => lambda { |server, worker|
        server.logger.info("worker=#{worker.nr} spawning...")
      },
    :before_exec => lambda { |server|
        server.logger.info("forked child re-executing...")
      },
    :pid => nil,
    :preload_app => false,
    :rewindable_input => true, # for Rack 2.x: (Rack::VERSION[0] <= 1),
    :client_body_buffer_size => Unicorn::Const::MAX_BODY,
    :trust_x_forwarded => true,
  }
  #:startdoc:

  def initialize(defaults = {}) #:nodoc:
    self.set = Hash.new(:unset)
    @use_defaults = defaults.delete(:use_defaults)
    self.config_file = defaults.delete(:config_file)

    # after_reload is only used by unicorn_rails, unsupported otherwise
    self.after_reload = defaults.delete(:after_reload)

    set.merge!(DEFAULTS) if @use_defaults
    defaults.each { |key, value| self.__send__(key, value) }
    Hash === set[:listener_opts] or
        set[:listener_opts] = Hash.new { |hash,key| hash[key] = {} }
    Array === set[:listeners] or set[:listeners] = []
    reload(false)
  end

  def reload(merge_defaults = true) #:nodoc:
    if merge_defaults && @use_defaults
      set.merge!(DEFAULTS) if @use_defaults
    end
    instance_eval(File.read(config_file), config_file) if config_file

    parse_rackup_file

    RACKUP[:set_listener] and
      set[:listeners] << "#{RACKUP[:host]}:#{RACKUP[:port]}"

    # unicorn_rails creates dirs here after working_directory is bound
    after_reload.call if after_reload

    # working_directory binds immediately (easier error checking that way),
    # now ensure any paths we changed are correctly set.
    [ :pid, :stderr_path, :stdout_path ].each do |var|
      String === (path = set[var]) or next
      path = File.expand_path(path)
      File.writable?(path) || File.writable?(File.dirname(path)) or \
            raise ArgumentError, "directory for #{var}=#{path} not writable"
    end
  end

  def commit!(server, options = {}) #:nodoc:
    skip = options[:skip] || []
    if ready_pipe = RACKUP.delete(:ready_pipe)
      server.ready_pipe = ready_pipe
    end
    set.each do |key, value|
      value == :unset and next
      skip.include?(key) and next
      server.__send__("#{key}=", value)
    end
  end

  def [](key) # :nodoc:
    set[key]
  end

  # sets object to the +obj+ Logger-like object.  The new Logger-like
  # object must respond to the following methods:
  # * debug
  # * info
  # * warn
  # * error
  # * fatal
  # The default Logger will log its output to the path specified
  # by +stderr_path+.  If you're running Unicorn daemonized, then
  # you must specify a path to prevent error messages from going
  # to /dev/null.
  def logger(obj)
    %w(debug info warn error fatal).each do |m|
      obj.respond_to?(m) and next
      raise ArgumentError, "logger=#{obj} does not respond to method=#{m}"
    end

    set[:logger] = obj
  end

  # sets after_fork hook to a given block.  This block will be called by
  # the worker after forking.  The following is an example hook which adds
  # a per-process listener to every worker:
  #
  #  after_fork do |server,worker|
  #    # per-process listener ports for debugging/admin:
  #    addr = "127.0.0.1:#{9293 + worker.nr}"
  #
  #    # the negative :tries parameter indicates we will retry forever
  #    # waiting on the existing process to exit with a 5 second :delay
  #    # Existing options for Unicorn::Configurator#listen such as
  #    # :backlog, :rcvbuf, :sndbuf are available here as well.
  #    server.listen(addr, :tries => -1, :delay => 5, :backlog => 128)
  #  end
  def after_fork(*args, &block)
    set_hook(:after_fork, block_given? ? block : args[0])
  end

  # sets before_fork got be a given Proc object.  This Proc
  # object will be called by the master process before forking
  # each worker.
  def before_fork(*args, &block)
    set_hook(:before_fork, block_given? ? block : args[0])
  end

  # sets the before_exec hook to a given Proc object.  This
  # Proc object will be called by the master process right
  # before exec()-ing the new unicorn binary.  This is useful
  # for freeing certain OS resources that you do NOT wish to
  # share with the reexeced child process.
  # There is no corresponding after_exec hook (for obvious reasons).
  def before_exec(*args, &block)
    set_hook(:before_exec, block_given? ? block : args[0], 1)
  end

  # sets the timeout of worker processes to +seconds+.  Workers
  # handling the request/app.call/response cycle taking longer than
  # this time period will be forcibly killed (via SIGKILL).  This
  # timeout is enforced by the master process itself and not subject
  # to the scheduling limitations by the worker process.  Due the
  # low-complexity, low-overhead implementation, timeouts of less
  # than 3.0 seconds can be considered inaccurate and unsafe.
  #
  # For running Unicorn behind nginx, it is recommended to set
  # "fail_timeout=0" for in your nginx configuration like this
  # to have nginx always retry backends that may have had workers
  # SIGKILL-ed due to timeouts.
  #
  #    # See http://wiki.nginx.org/NginxHttpUpstreamModule for more details
  #    # on nginx upstream configuration:
  #    upstream unicorn_backend {
  #      # for UNIX domain socket setups:
  #      server unix:/path/to/unicorn.sock fail_timeout=0;
  #
  #      # for TCP setups
  #      server 192.168.0.7:8080 fail_timeout=0;
  #      server 192.168.0.8:8080 fail_timeout=0;
  #      server 192.168.0.9:8080 fail_timeout=0;
  #    }
  def timeout(seconds)
    set_int(:timeout, seconds, 3)
    max = 0x7ffffffe # Rainbows! adds one second to this for safety
    set[:timeout] = seconds > max ? max : seconds
  end

  # sets the current number of worker_processes to +nr+.  Each worker
  # process will serve exactly one client at a time.  You can
  # increment or decrement this value at runtime by sending SIGTTIN
  # or SIGTTOU respectively to the master process without reloading
  # the rest of your Unicorn configuration.  See the SIGNALS document
  # for more information.
  def worker_processes(nr)
    set_int(:worker_processes, nr, 1)
  end

  # sets listeners to the given +addresses+, replacing or augmenting the
  # current set.  This is for the global listener pool shared by all
  # worker processes.  For per-worker listeners, see the after_fork example
  # This is for internal API use only, do not use it in your Unicorn
  # config file.  Use listen instead.
  def listeners(addresses) # :nodoc:
    Array === addresses or addresses = Array(addresses)
    addresses.map! { |addr| expand_addr(addr) }
    set[:listeners] = addresses
  end

  # Adds an +address+ to the existing listener set.  May be specified more
  # than once.  +address+ may be an Integer port number for a TCP port, an
  # "IP_ADDRESS:PORT" for TCP listeners or a pathname for UNIX domain sockets.
  #
  #   listen 3000 # listen to port 3000 on all TCP interfaces
  #   listen "127.0.0.1:3000"  # listen to port 3000 on the loopback interface
  #   listen "/tmp/.unicorn.sock" # listen on the given Unix domain socket
  #   listen "[::1]:3000" # listen to port 3000 on the IPv6 loopback interface
  #
  # The following options may be specified (but are generally not needed):
  #
  # [:backlog => number of clients]
  #
  #   This is the backlog of the listen() syscall.
  #
  #   Some operating systems allow negative values here to specify the
  #   maximum allowable value.  In most cases, this number is only
  #   recommendation and there are other OS-specific tunables and
  #   variables that can affect this number.  See the listen(2)
  #   syscall documentation of your OS for the exact semantics of
  #   this.
  #
  #   If you are running unicorn on multiple machines, lowering this number
  #   can help your load balancer detect when a machine is overloaded
  #   and give requests to a different machine.
  #
  #   Default: 1024
  #
  # [:rcvbuf => bytes, :sndbuf => bytes]
  #
  #   Maximum receive and send buffer sizes (in bytes) of sockets.
  #
  #   These correspond to the SO_RCVBUF and SO_SNDBUF settings which
  #   can be set via the setsockopt(2) syscall.  Some kernels
  #   (e.g. Linux 2.4+) have intelligent auto-tuning mechanisms and
  #   there is no need (and it is sometimes detrimental) to specify them.
  #
  #   See the socket API documentation of your operating system
  #   to determine the exact semantics of these settings and
  #   other operating system-specific knobs where they can be
  #   specified.
  #
  #   Defaults: operating system defaults
  #
  # [:tcp_nodelay => true or false]
  #
  #   Disables Nagle's algorithm on TCP sockets if +true+.
  #
  #   Setting this to +true+ can make streaming responses in Rails 3.1
  #   appear more quickly at the cost of slightly higher bandwidth usage.
  #   The effect of this option is most visible if nginx is not used,
  #   but nginx remains highly recommended with \Unicorn.
  #
  #   This has no effect on UNIX sockets.
  #
  #   Default: +true+ (Nagle's algorithm disabled) in \Unicorn,
  #   +true+ in Rainbows!  This defaulted to +false+ in \Unicorn
  #   3.x
  #
  # [:tcp_nopush => true or false]
  #
  #   Enables/disables TCP_CORK in Linux or TCP_NOPUSH in FreeBSD
  #
  #   This prevents partial TCP frames from being sent out and reduces
  #   wakeups in nginx if it is on a different machine.  Since \Unicorn
  #   is only designed for applications that send the response body
  #   quickly without keepalive, sockets will always be flushed on close
  #   to prevent delays.
  #
  #   This has no effect on UNIX sockets.
  #
  #   Default: +false+
  #   This defaulted to +true+ in \Unicorn 3.4 - 3.7
  #
  # [:ipv6only => true or false]
  #
  #   This option makes IPv6-capable TCP listeners IPv6-only and unable
  #   to receive IPv4 queries on dual-stack systems.  A separate IPv4-only
  #   listener is required if this is true.
  #
  #   This option is only available for Ruby 1.9.2 and later.
  #
  #   Enabling this option for the IPv6-only listener and having a
  #   separate IPv4 listener is recommended if you wish to support IPv6
  #   on the same TCP port.  Otherwise, the value of \env[\"REMOTE_ADDR\"]
  #   will appear as an ugly IPv4-mapped-IPv6 address for IPv4 clients
  #   (e.g ":ffff:10.0.0.1" instead of just "10.0.0.1").
  #
  #   Default: Operating-system dependent
  #
  # [:tries => Integer]
  #
  #   Times to retry binding a socket if it is already in use
  #
  #   A negative number indicates we will retry indefinitely, this is
  #   useful for migrations and upgrades when individual workers
  #   are binding to different ports.
  #
  #   Default: 5
  #
  # [:delay => seconds]
  #
  #   Seconds to wait between successive +tries+
  #
  #   Default: 0.5 seconds
  #
  # [:umask => mode]
  #
  #   Sets the file mode creation mask for UNIX sockets.  If specified,
  #   this is usually in octal notation.
  #
  #   Typically UNIX domain sockets are created with more liberal
  #   file permissions than the rest of the application.  By default,
  #   we create UNIX domain sockets to be readable and writable by
  #   all local users to give them the same accessibility as
  #   locally-bound TCP listeners.
  #
  #   This has no effect on TCP listeners.
  #
  #   Default: 0000 (world-read/writable)
  #
  # [:tcp_defer_accept => Integer]
  #
  #   Defer accept() until data is ready (Linux-only)
  #
  #   For Linux 2.6.32 and later, this is the number of retransmits to
  #   defer an accept() for if no data arrives, but the client will
  #   eventually be accepted after the specified number of retransmits
  #   regardless of whether data is ready.
  #
  #   For Linux before 2.6.32, this is a boolean option, and
  #   accepts are _always_ deferred indefinitely if no data arrives.
  #   This is similar to <code>:accept_filter => "dataready"</code>
  #   under FreeBSD.
  #
  #   Specifying +true+ is synonymous for the default value(s) below,
  #   and +false+ or +nil+ is synonymous for a value of zero.
  #
  #   A value of +1+ is a good optimization for local networks
  #   and trusted clients.  For Rainbows! and Zbatery users, a higher
  #   value (e.g. +60+) provides more protection against some
  #   denial-of-service attacks.  There is no good reason to ever
  #   disable this with a +zero+ value when serving HTTP.
  #
  #   Default: 1 retransmit for \Unicorn, 60 for Rainbows! 0.95.0\+
  #
  # [:accept_filter => String]
  #
  #   defer accept() until data is ready (FreeBSD-only)
  #
  #   This enables either the "dataready" or (default) "httpready"
  #   accept() filter under FreeBSD.  This is intended as an
  #   optimization to reduce context switches with common GET/HEAD
  #   requests.  For Rainbows! and Zbatery users, this provides
  #   some protection against certain denial-of-service attacks, too.
  #
  #   There is no good reason to change from the default.
  #
  #   Default: "httpready"
  def listen(address, options = {})
    address = expand_addr(address)
    if String === address
      [ :umask, :backlog, :sndbuf, :rcvbuf, :tries ].each do |key|
        value = options[key] or next
        Integer === value or
          raise ArgumentError, "not an integer: #{key}=#{value.inspect}"
      end
      [ :tcp_nodelay, :tcp_nopush, :ipv6only ].each do |key|
        (value = options[key]).nil? and next
        TrueClass === value || FalseClass === value or
          raise ArgumentError, "not boolean: #{key}=#{value.inspect}"
      end
      unless (value = options[:delay]).nil?
        Numeric === value or
          raise ArgumentError, "not numeric: delay=#{value.inspect}"
      end
      set[:listener_opts][address].merge!(options)
    end

    set[:listeners] << address
  end

  # sets the +path+ for the PID file of the unicorn master process
  def pid(path); set_path(:pid, path); end

  # Enabling this preloads an application before forking worker
  # processes.  This allows memory savings when using a
  # copy-on-write-friendly GC but can cause bad things to happen when
  # resources like sockets are opened at load time by the master
  # process and shared by multiple children.  People enabling this are
  # highly encouraged to look at the before_fork/after_fork hooks to
  # properly close/reopen sockets.  Files opened for logging do not
  # have to be reopened as (unbuffered-in-userspace) files opened with
  # the File::APPEND flag are written to atomically on UNIX.
  #
  # In addition to reloading the unicorn-specific config settings,
  # SIGHUP will reload application code in the working
  # directory/symlink when workers are gracefully restarted when
  # preload_app=false (the default).  As reloading the application
  # sometimes requires RubyGems updates, +Gem.refresh+ is always
  # called before the application is loaded (for RubyGems users).
  #
  # During deployments, care should _always_ be taken to ensure your
  # applications are properly deployed and running.  Using
  # preload_app=false (the default) means you _must_ check if
  # your application is responding properly after a deployment.
  # Improperly deployed applications can go into a spawn loop
  # if the application fails to load.  While your children are
  # in a spawn loop, it is is possible to fix an application
  # by properly deploying all required code and dependencies.
  # Using preload_app=true means any application load error will
  # cause the master process to exit with an error.

  def preload_app(bool)
    set_bool(:preload_app, bool)
  end

  # Toggles making \env[\"rack.input\"] rewindable.
  # Disabling rewindability can improve performance by lowering
  # I/O and memory usage for applications that accept uploads.
  # Keep in mind that the Rack 1.x spec requires
  # \env[\"rack.input\"] to be rewindable, so this allows
  # intentionally violating the current Rack 1.x spec.
  #
  # +rewindable_input+ defaults to +true+ when used with Rack 1.x for
  # Rack conformance.  When Rack 2.x is finalized, this will most
  # likely default to +false+ while still conforming to the newer
  # (less demanding) spec.
  def rewindable_input(bool)
    set_bool(:rewindable_input, bool)
  end

  # The maximum size (in +bytes+) to buffer in memory before
  # resorting to a temporary file.  Default is 112 kilobytes.
  # This option has no effect if "rewindable_input" is set to
  # +false+.
  def client_body_buffer_size(bytes)
    set_int(:client_body_buffer_size, bytes, 0)
  end

  # Allow redirecting $stderr to a given path.  Unlike doing this from
  # the shell, this allows the unicorn process to know the path its
  # writing to and rotate the file if it is used for logging.  The
  # file will be opened with the File::APPEND flag and writes
  # synchronized to the kernel (but not necessarily to _disk_) so
  # multiple processes can safely append to it.
  #
  # If you are daemonizing and using the default +logger+, it is important
  # to specify this as errors will otherwise be lost to /dev/null.
  # Some applications/libraries may also triggering warnings that go to
  # stderr, and they will end up here.
  def stderr_path(path)
    set_path(:stderr_path, path)
  end

  # Same as stderr_path, except for $stdout.  Not many Rack applications
  # write to $stdout, but any that do will have their output written here.
  # It is safe to point this to the same location a stderr_path.
  # Like stderr_path, this defaults to /dev/null when daemonized.
  def stdout_path(path)
    set_path(:stdout_path, path)
  end

  # sets the working directory for Unicorn.  This ensures SIGUSR2 will
  # start a new instance of Unicorn in this directory.  This may be
  # a symlink, a common scenario for Capistrano users.  Unlike
  # all other Unicorn configuration directives, this binds immediately
  # for error checking and cannot be undone by unsetting it in the
  # configuration file and reloading.
  def working_directory(path)
    # just let chdir raise errors
    path = File.expand_path(path)
    if config_file &&
       config_file[0] != ?/ &&
       ! File.readable?("#{path}/#{config_file}")
      raise ArgumentError,
            "config_file=#{config_file} would not be accessible in" \
            " working_directory=#{path}"
    end
    Dir.chdir(path)
    Unicorn::HttpServer::START_CTX[:cwd] = ENV["PWD"] = path
  end

  # Runs worker processes as the specified +user+ and +group+.
  # The master process always stays running as the user who started it.
  # This switch will occur after calling the after_fork hook, and only
  # if the Worker#user method is not called in the after_fork hook
  # +group+ is optional and will not change if unspecified.
  def user(user, group = nil)
    # raises ArgumentError on invalid user/group
    Etc.getpwnam(user)
    Etc.getgrnam(group) if group
    set[:user] = [ user, group ]
  end

  # Sets whether or not the parser will trust X-Forwarded-Proto and
  # X-Forwarded-SSL headers and set "rack.url_scheme" to "https" accordingly.
  # Rainbows!/Zbatery installations facing untrusted clients directly
  # should set this to +false+.  This is +true+ by default as Unicorn
  # is designed to only sit behind trusted nginx proxies.
  #
  # This has never been publically documented and is subject to removal
  # in future releases.
  def trust_x_forwarded(bool) # :nodoc:
    set_bool(:trust_x_forwarded, bool)
  end

  # expands "unix:path/to/foo" to a socket relative to the current path
  # expands pathnames of sockets if relative to "~" or "~username"
  # expands "*:port and ":port" to "0.0.0.0:port"
  def expand_addr(address) #:nodoc:
    return "0.0.0.0:#{address}" if Integer === address
    return address unless String === address

    case address
    when %r{\Aunix:(.*)\z}
      File.expand_path($1)
    when %r{\A~}
      File.expand_path(address)
    when %r{\A(?:\*:)?(\d+)\z}
      "0.0.0.0:#$1"
    when %r{\A\[([a-fA-F0-9:]+)\]\z}, %r/\A((?:\d+\.){3}\d+)\z/
      canonicalize_tcp($1, 80)
    when %r{\A\[([a-fA-F0-9:]+)\]:(\d+)\z}, %r{\A(.*):(\d+)\z}
      canonicalize_tcp($1, $2.to_i)
    else
      address
    end
  end

private
  def set_int(var, n, min) #:nodoc:
    Integer === n or raise ArgumentError, "not an integer: #{var}=#{n.inspect}"
    n >= min or raise ArgumentError, "too low (< #{min}): #{var}=#{n.inspect}"
    set[var] = n
  end

  def canonicalize_tcp(addr, port)
    packed = Socket.pack_sockaddr_in(port, addr)
    port, addr = Socket.unpack_sockaddr_in(packed)
    /:/ =~ addr ? "[#{addr}]:#{port}" : "#{addr}:#{port}"
  end

  def set_path(var, path) #:nodoc:
    case path
    when NilClass, String
      set[var] = path
    else
      raise ArgumentError
    end
  end

  def set_bool(var, bool) #:nodoc:
    case bool
    when true, false
      set[var] = bool
    else
      raise ArgumentError, "#{var}=#{bool.inspect} not a boolean"
    end
  end

  def set_hook(var, my_proc, req_arity = 2) #:nodoc:
    case my_proc
    when Proc
      arity = my_proc.arity
      (arity == req_arity) or \
        raise ArgumentError,
              "#{var}=#{my_proc.inspect} has invalid arity: " \
              "#{arity} (need #{req_arity})"
    when NilClass
      my_proc = DEFAULTS[var]
    else
      raise ArgumentError, "invalid type: #{var}=#{my_proc.inspect}"
    end
    set[var] = my_proc
  end

  # this is called _after_ working_directory is bound.  This only
  # parses the embedded switches in .ru files
  # (for "rackup" compatibility)
  def parse_rackup_file # :nodoc:
    ru = RACKUP[:file] or return # we only return here in unit tests

    # :rails means use (old) Rails autodetect
    if ru == :rails
      File.readable?('config.ru') or return
      ru = 'config.ru'
    end

    File.readable?(ru) or
      raise ArgumentError, "rackup file (#{ru}) not readable"

    # it could be a .rb file, too, we don't parse those manually
    ru =~ /\.ru\z/ or return

    /^#\\(.*)/ =~ File.read(ru) or return
    RACKUP[:optparse].parse!($1.split(/\s+/))

    if RACKUP[:daemonize]
      # unicorn_rails wants a default pid path, (not plain 'unicorn')
      if after_reload
        spid = set[:pid]
        pid('tmp/pids/unicorn.pid') if spid.nil? || spid == :unset
      end
      unless RACKUP[:daemonized]
        Unicorn::Launcher.daemonize!(RACKUP[:options])
        RACKUP[:ready_pipe] = RACKUP[:options].delete(:ready_pipe)
      end
    end
  end
end

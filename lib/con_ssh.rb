
require 'ostruct'
require 'con_ssh/core_extensions'

class SSHCon
  CONF_PATH = File.expand_path '~/.con'
  CONF_LINE_FIELDS = %w(shortcut conn_desc host user port knock unknock)
  DEFAULT_PORT = "22"

  def initialize
    @conn_confs = {}
  end

  def run *args
    # setup
    if args[0] == 'setup'
      warn "Ignoring arguments after #{args[0]}." if args.length > 1
      install_sample_conf

    # knock / unknock
    elsif ['knock', 'unknock'].include? args[1] 
      warn "Ignoring arguments after #{args[1]}." if args.length > 2
      parse_conf
      conn_conf = @conn_confs[args[0]]
      unless conn_confs
        warn "Shorcut #{args[0]} not found. See #{CONF_PATH}."
        exit 1
      end
      ports = conn_conf[args[1]]
      if ports.nil? || ports.empty?
        warn "#{conn_conf.conn_desc} has no #{args[1]} configuration."
        exit 1
      end
      knock conn_conf.host, ports

    # connect
    elsif conn_conf = @conn_confs[args[0]]
      warn "Ignoring arguments after #{args[0]}." if args.length > 1      
      parse_conf
      ssh conn_conf

    # help
    elsif ['-h'].include? args[0]
      warn "Ignoring arguments after #{args[0]}." if args.length > 1      
      print_help

    # fail
    else
      warn "Invalid arguments."
      print_help
      exit 1
    end
  end

  private

  def ssh c
    port = (c.port && c.port != DEFAULT_PORT) ? "-p #{ c.port } " : ''
    user = c.user ? "#{ c.user }@" : ''
    knock c.host, c.knock if c.knock
    system "ssh #{port}#{user}#{c.host}"
    knock c.host, c.unknock if c.unknock
  end

  def knock host, ports
    unless has_knock
        msg = "Skipping knock! 
             The connection configuration has ports knock set but you don`t have 'knock' installed on your system. 
             Please install: 'apt-get install knockd', 'brew install knock', ...".strip_text
        warn msg
      return
      end
    run_cmd "knock #{ host } #{ ports.join ' ' }", false
  end


  # Conf

  def parse_conf
    unless File.exists? CONF_PATH
      raise "#{CONF_PATH} not found. Install a sample with 'con setup'."
    end
    File.open(CONF_PATH).readlines.each do |line|
      add_connection line.strip     
    end
  end

  def add_connection line
    return if skip_line? line
    
    values = line.split /\s+/
    
    conn_conf = OpenStruct.new
    CONF_LINE_FIELDS.each_with_index do |field, idx|
      conn_conf[field.to_sym] = values[idx]
    end

    unless valid? conn_conf
      warn "WARNING: Invalid line, skipping: '#{line}'"
      return
    end

    adjust_conn_conf conn_conf

    if @conn_confs[conn_conf.shortcut]
      warn "WARNING: Shorcut '#{conn_conf.shortcut} is duplicated, skipping line: '#{line}'"
      return
    end

    @conn_confs[conn_conf.shortcut] = conn_conf
  end

  def valid? c
    c.shortcut &&
    c.conn_desc &&
    c.host
  end

  def adjust_conn_conf c
    c.knock  = c.knock.split  ',' if c.knock 
    c.unknock = c.unknock.split ',' if c.unknock 

    if c.host =~ /^(.*?)@(.*?)$/
      c.host = $2
      c.user ||= $1
    end
  end

  def install_sample_conf
    if File.exists? CONF_PATH
      warn "#{CONF_PATH} already exists. Skipping install."
      return false
    end
    sample_conf = "# #{ CONF_LINE_FIELDS.join ' ' }
    # *connection_desc must have no spaces.
    # *user, port, knock, unknock are optionals.

    s1  server_1  123.234.35.456
    s1r server_1r root@123.234.35.456
    s3  server_3  123.234.35.456  username  2222  knock unknock"
    File.write CONF_PATH, sample_conf.strip_text
    true
  end


  # Util
  
  def warn desc
    $stderr.puts desc
  end

  def skip_line? line
    line =~ /^\s*[$#]/
  end

  def has_knock
    !`which knock`.strip.empty?
  end

  def print_help
    puts "Usage: con <shortcut>|setup [knock|unknock]".strip_text
  end

  def run_cmd cmd, print = true
    puts "run: #{cmd}" if print
      output = `#{cmd} 2>&1`
      exit_status = $?.to_i
      unless exit_status == 0
      warn "Non-zero output: #{output}"
    end
    [exit_status, output]
  end
end

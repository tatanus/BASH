#
# msf_common_runner.rb
#
# Defines a single entry point `run_module(opts)` that takes a hash of
# per-module settings and performs the common Metasploit workflow.
#

def run_module(opts = {})
  #── Extract options ──────────────────────────────────────────────────────────
  module_path   = opts[:module_path]
  target_filter = opts[:target_filter]
  thread_count  = opts[:thread_count]
  user_file     = opts[:user_file]
  pass_file     = opts[:pass_file]
  username      = opts[:username]
  password      = opts[:password]

  #── Sanity check ─────────────────────────────────────────────────────────────
  unless module_path
    print_error("module_path is not defined. Cannot continue.")
    exit
  end

  #── Prepare output paths ─────────────────────────────────────────────────────
  module_name = module_path.split("/").last
  tee_dir     = "/root/DATA/OUTPUT/TEE"
  tee_log     = "#{tee_dir}/MSF_#{module_name}.tee"

  #── Ensure tee directory ─────────────────────────────────────────────────────
  unless File.directory?(tee_dir)
    print_status("Creating tee directory: #{tee_dir}")
    begin
      Dir.mkdir(tee_dir)
    rescue => e
      print_error("Failed to create directory #{tee_dir}: #{e}")
      exit
    end
  end

  #── Module setup ─────────────────────────────────────────────────────────────
  print_status("Using module: #{module_path}")
  run_single("use #{module_path}")
  run_single("set THREADS #{thread_count}")   if thread_count
  run_single("set USER_FILE #{user_file}")   if user_file
  run_single("set PASS_FILE #{pass_file}")   if pass_file
  run_single("set USERNAME #{username}")     if username
  run_single("set PASSWORD #{password}")     if password
  #run_single("set VERBOSE true")
  run_single("spool #{tee_log}")

  #── Parallelized Target Loop ────────────────────────────────────────────────
  begin

    # **Grab a Ruby module instance so we can inspect its option names**
    mod = framework.modules.create(module_path)

    services_by_port = Hash.new { |h,k| h[k] = [] }
    framework.db.hosts.each do |host|
      host.services.each do |s|
        next unless s.proto == target_filter[:proto] && s.state == "open"
        nm = target_filter[:services].map(&:downcase)
        pm = target_filter[:ports]
        next unless nm.include?(s.name.to_s.downcase) || pm.include?(s.port)
        services_by_port[s.port] << host.address
      end
    end

    services_by_port.each do |port, hosts|
      uniq = hosts.uniq
      next if uniq.empty?
      #print_status("Targeting #{uniq.size} hosts on port #{port}: #{uniq.join(' ')}")
      print_status("Targeting #{uniq.size} hosts on port #{port}.")
      run_single("set RHOSTS #{uniq.join(' ')}")

      # **Only set RPORT if the module actually defines it**
      if mod.options.key?("RPORT")
        run_single("set RPORT #{port}")
      else
        print_status("Skipping RPORT — #{module_path} doesn’t support it.")
	    end

      #run_single("run -j")
      run_single("run")
    end

    # Optionally wait for all jobs to finish before cleanup:
    # sleep 1 while framework.jobs.list.any? { |j| j['name'] =~ /#{module_name}/ }
  rescue => e
    print_error("Error during run: #{e}")
  end

  #── Cleanup ─────────────────────────────────────────────────────────────────
  run_single("spool off")
  run_single("back")
end
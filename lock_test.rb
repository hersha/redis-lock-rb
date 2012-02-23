def start
  unless File.exists?("/usr/local/var/run/lock_test.pid")
    require "redis"
    require "/Users/pneff/Development/redis_lock/redis_lock"
    forks = []
    16.times do
      forks << fork do
        r = Redis.new
        r.extend RedisLock
        pid = Process.pid
        counter = 0
        trap("SIGINT") { puts "Stopping Child - #{pid}"; exit!}
        puts "Created Child - #{pid}"
        while 1
          if r.lock('buffer', 5)
            counter += 1
            puts "#{counter} - #{pid} - Got Lock"
            sleep 1
            if r.unlock('buffer')
              puts "#{pid} - Dropped Lock"
            end
            sleep 1
          else
            # puts "#{pid} - Already Locked"
            sleep 1
          end

        end
      end
    end
    File.open("/usr/local/var/run/lock_test.pid", "w") { |file|  forks.each { |f| file.puts f } }
  else
    puts "System already running."
  end
end

def stop
  begin
    File.open("/usr/local/var/run/lock_test.pid", "r") do |file|
      while pid = file.gets
        begin
          Process.kill("SIGINT", pid.to_i)
        rescue Exception => e
          puts "Worker #{pid.to_i} already stopped."
        end
      end
    end
    File.delete("/usr/local/var/run/lock_test.pid")
  rescue Exception => e
    puts "Error : Must start process first"
  end
end

def restart
  stop
  start
end

case ARGV[0]
when "start"
  start
when "stop"
  stop
when "restart"
  restart
end
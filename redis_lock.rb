module RedisLock
  def lock_for_update(key, timeout = 60, max_attempts = 100)
    if self.lock(key, timeout, max_attempts)
      response = yield if block_given?
      self.unlock(key)
      return response
    else
      sleep 1
    end
  end

  def lock(key, timeout = 60, max_attempts = 100)
    current_lock_key = lock_key(key)
    expiration_value = lock_expiration(timeout)
    attempt_counter = 0
    # begin
      if self.setnx(current_lock_key, expiration_value) and self.expire(current_lock_key, timeout)
        return true
      else
        return false
        # raise "Unable to acquire lock for #{key}."
      end
    # rescue => e
    #   if e.message == "Unable to acquire lock for #{key}."
    #     if attempt_counter == max_attempts
    #       raise
    #     else
    #       attempt_counter += 1
    #       sleep 1
    #       retry
    #     end
    #   else
    #     raise
    #   end
    # end
  end

  def unlock(key)
    current_lock_key = lock_key(key)
    lock_value = self.get(current_lock_key)
    return true unless lock_value
    lock_timeout, lock_holder = lock_value.split('-')
    if (lock_timeout.to_i > Time.now.to_i) && (lock_holder.to_i == Process.pid)
      self.del(current_lock_key)
      return true
    else
      return false
    end
  end

  private

  def lock_expiration(timeout)
    "#{Time.now.to_i + timeout + 1}-#{Process.pid}"
  end

  def lock_key(key)
    "lock:#{key}"
  end
end
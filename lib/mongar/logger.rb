class Mongar
  module Logger
    def info(log_message)
      return unless @log_level && [:info, :debug].include?(@log_level)
      
      puts "Info: #{log_message}"
    end
    
    def debug(log_message)
      return unless @log_level && @log_level == :debug
      
      puts "Debug: #{log_message}"
    end
  end
end

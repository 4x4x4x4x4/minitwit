require 'logger'
require 'json'
require 'fileutils'

class LoggerSetup
  LEVELS = %w[DEBUG INFO WARN ERROR FATAL UNKNOWN]

  def self.build(log_dir = 'Logs')
    FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)

    # Create a logger for each level
    loggers = LEVELS.each_with_object({}) do |level, hash|
      file_path = File.join(log_dir, "#{level.downcase}.log")
      logger = Logger.new(file_path)
      logger.level = Logger.const_get(level)
      logger.formatter = proc do |severity, datetime, progname, msg|
        {
          timestamp: datetime.utc.iso8601,
          severity: severity,
          message: msg
        }.to_json + "\n"
      end
      hash[level] = logger
    end

    MultiLevelLogger.new(loggers)
  end

  class MultiLevelLogger
    def initialize(loggers)
      @loggers = loggers
    end

    Logger::Severity.constants.each do |level_sym|
      level_str = level_sym.to_s
      define_method(level_str.downcase) do |msg|
        @loggers[level_str]&.send(level_str.downcase, msg)
      end
    end
  end
end

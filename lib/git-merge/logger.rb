module GitMerge
  Logger = ::Logger.new(STDOUT)
  Logger.level = ::Logger::INFO
  Logger.formatter = proc do |severity, datetime, progname, msg|
    "#{msg}\n"
  end
end

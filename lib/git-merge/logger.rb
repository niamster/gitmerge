module GitMerge
  Logger = ::Logger.new(STDOUT)
  Logger.level = ::Logger::INFO
  Logger.formatter = proc do |severity, datetime, progname, msg|
    severity.downcase!
    if ['debug', 'info'].include? severity
      severity = ''
    else
      severity = "#{severity}: "
    end
    "#{severity}#{msg}\n"
  end
end

Rails.application.config.after_initialize do
  IntegrityLogger.config do |c|
    c.adapter = IntegrityLogActiveRecordAdapter.new
  end
end

#from: https://coderwall.com/p/dz6ttq
# This initializer adds a method, show_mongo, when running a rails console. When active, all
# moped commands (moped is mongoid's mongodb driver) will be logged inline in the console output.
# If called again, logging will be restored to normal (written to log files, not shown inline).
# Usage:
#     > show_mongo

if defined?(Rails::Console)
  def show_mongo
    if Moped.logger == Rails.logger
      Moped.logger = Logger.new($stdout)
      true
    else
      Moped.logger = Rails.logger
      false
    end
  end
  alias :show_moped :show_mongo
end
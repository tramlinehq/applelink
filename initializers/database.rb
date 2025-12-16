require "sqlite3"
require "fileutils"

module Initializers
  module Database
    DB_PATH = ENV.fetch("DATABASE_PATH", "db/applelink.sqlite3")

    def self.connection
      @connection ||= begin
        FileUtils.mkdir_p(File.dirname(DB_PATH))
        db = SQLite3::Database.new(DB_PATH)
        db.results_as_hash = true
        db
      end
    end

    def self.setup!
      connection.execute <<-SQL
        CREATE TABLE IF NOT EXISTS upload_status (
          id TEXT PRIMARY KEY,
          app_id TEXT NOT NULL,
          bundle_id TEXT NOT NULL,
          ipa_url TEXT NOT NULL,
          cf_bundle_short_version TEXT NOT NULL,
          cf_bundle_version TEXT NOT NULL,
          state TEXT NOT NULL DEFAULT 'pending',
          build_upload_id TEXT,
          build_upload_file_id TEXT,
          parts_total INTEGER DEFAULT 0,
          parts_uploaded INTEGER DEFAULT 0,
          retry_count INTEGER DEFAULT 0,
          error_message TEXT,
          ipa_name TEXT,
          ipa_size INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          started_at TEXT,
          completed_at TEXT
        )
      SQL

      connection.execute <<-SQL
        CREATE INDEX IF NOT EXISTS idx_upload_status_state ON upload_status(state)
      SQL

      connection.execute <<-SQL
        CREATE INDEX IF NOT EXISTS idx_upload_status_app_id ON upload_status(app_id)
      SQL
    end
  end
end

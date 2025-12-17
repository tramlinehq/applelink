require "securerandom"
require_relative "../../initializers/database"

module AppStore
  class UploadStatus
    STATES = %w[pending downloading uploading committing completed failed].freeze

    attr_reader :id, :app_id, :bundle_id, :ipa_url, :cf_bundle_short_version, :cf_bundle_version,
      :state, :build_upload_id, :build_upload_file_id, :parts_total, :parts_uploaded,
      :retry_count, :error_message, :ipa_name, :ipa_size,
      :created_at, :updated_at, :started_at, :completed_at

    def initialize(attrs = {})
      @id = attrs["id"] || attrs[:id]
      @app_id = attrs["app_id"] || attrs[:app_id]
      @bundle_id = attrs["bundle_id"] || attrs[:bundle_id]
      @ipa_url = attrs["ipa_url"] || attrs[:ipa_url]
      @cf_bundle_short_version = attrs["cf_bundle_short_version"] || attrs[:cf_bundle_short_version]
      @cf_bundle_version = attrs["cf_bundle_version"] || attrs[:cf_bundle_version]
      @state = attrs["state"] || attrs[:state] || "pending"
      @build_upload_id = attrs["build_upload_id"] || attrs[:build_upload_id]
      @build_upload_file_id = attrs["build_upload_file_id"] || attrs[:build_upload_file_id]
      @parts_total = attrs["parts_total"] || attrs[:parts_total] || 0
      @parts_uploaded = attrs["parts_uploaded"] || attrs[:parts_uploaded] || 0
      @retry_count = attrs["retry_count"] || attrs[:retry_count] || 0
      @error_message = attrs["error_message"] || attrs[:error_message]
      @ipa_name = attrs["ipa_name"] || attrs[:ipa_name]
      @ipa_size = attrs["ipa_size"] || attrs[:ipa_size]
      @created_at = attrs["created_at"] || attrs[:created_at]
      @updated_at = attrs["updated_at"] || attrs[:updated_at]
      @started_at = attrs["started_at"] || attrs[:started_at]
      @completed_at = attrs["completed_at"] || attrs[:completed_at]
    end

    def self.db
      Initializers::Database.connection
    end

    def self.create(app_id:, bundle_id:, ipa_url:, cf_bundle_short_version:, cf_bundle_version:)
      id = SecureRandom.uuid
      now = Time.now.utc.iso8601

      db.execute(<<-SQL, [id, app_id, bundle_id, ipa_url, cf_bundle_short_version, cf_bundle_version, "pending", now, now])
        INSERT INTO upload_status (
          id, app_id, bundle_id, ipa_url, cf_bundle_short_version, cf_bundle_version, state, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      SQL

      find(id)
    end

    def self.find(id)
      row = db.get_first_row("SELECT * FROM upload_status WHERE id = ?", [id])
      return nil unless row
      new(row)
    end

    def self.find_by_app(app_id, limit: 10)
      rows = db.execute("SELECT * FROM upload_status WHERE app_id = ? ORDER BY created_at DESC LIMIT ?", [app_id, limit])
      rows.map { |row| new(row) }
    end

    def update(attrs)
      attrs[:updated_at] = Time.now.utc.iso8601

      set_clauses = attrs.keys.map { |k| "#{k} = ?" }.join(", ")
      values = attrs.values + [id]

      self.class.db.execute("UPDATE upload_status SET #{set_clauses} WHERE id = ?", values)

      attrs.each do |k, v|
        instance_variable_set("@#{k}", v)
      end

      self
    end

    def transition_to!(new_state, attrs = {})
      raise ArgumentError, "Invalid state: #{new_state}" unless STATES.include?(new_state)

      attrs[:state] = new_state
      attrs[:started_at] = Time.now.utc.iso8601 if new_state == "downloading" && started_at.nil?
      attrs[:completed_at] = Time.now.utc.iso8601 if %w[completed failed].include?(new_state)

      update(attrs)
    end

    def increment_parts_uploaded!
      update(parts_uploaded: parts_uploaded + 1)
    end

    def increment_retry_count!
      update(retry_count: retry_count + 1)
    end

    def fail!(error_message)
      transition_to!("failed", error_message: error_message)
    end

    def pending?
      state == "pending"
    end

    def downloading?
      state == "downloading"
    end

    def uploading?
      state == "uploading"
    end

    def committing?
      state == "committing"
    end

    def completed?
      state == "completed"
    end

    def failed?
      state == "failed"
    end

    def in_progress?
      %w[pending downloading uploading committing].include?(state)
    end

    def to_h
      {
        id: id,
        app_id: app_id,
        bundle_id: bundle_id,
        ipa_url: ipa_url,
        cf_bundle_short_version: cf_bundle_short_version,
        cf_bundle_version: cf_bundle_version,
        state: state,
        build_upload_id: build_upload_id,
        build_upload_file_id: build_upload_file_id,
        parts_total: parts_total,
        parts_uploaded: parts_uploaded,
        retry_count: retry_count,
        error_message: error_message,
        ipa_name: ipa_name,
        ipa_size: ipa_size,
        created_at: created_at,
        updated_at: updated_at,
        started_at: started_at,
        completed_at: completed_at
      }
    end
  end
end

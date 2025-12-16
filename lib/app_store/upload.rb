require "net/http"
require "uri"
require "fileutils"
require "tempfile"
require "ougai"
require "retryable"
require_relative "errors"
require_relative "upload_status"

module AppStore
  class Upload
    ASC_API_BASE = "https://api.appstoreconnect.apple.com/v1".freeze
    IOS_PLATFORM = "IOS".freeze
    MAX_RETRIES = 3
    RETRY_BASE_SLEEP_SECONDS = 1
    PART_UPLOAD_TIMEOUT = 300 # 5 minutes per part

    def self.perform_async(token:, upload_status:)
      Thread.new do
        new(token: token, upload_status: upload_status).call
      rescue => e
        logger = ::Ougai::Logger.new($stdout)
        logger.error("Background upload failed", {upload_id: upload_status.id, error: e.message, backtrace: e.backtrace&.first(5)})
        Sentry.capture_exception(e) if defined?(Sentry)
      end
    end

    def initialize(token:, upload_status:)
      @token = token
      @upload_status = upload_status
      @logger = ::Ougai::Logger.new($stdout)
    end

    def call
      ipa_path = nil

      begin
        # Step 1: Download IPA
        @upload_status.transition_to!("downloading")
        ipa_path = download_ipa(@upload_status.ipa_url)

        ipa_name = File.basename(URI.parse(@upload_status.ipa_url).path)
        ipa_size = File.size(ipa_path)

        @upload_status.update(ipa_name: ipa_name, ipa_size: ipa_size)

        log("Starting IPA upload", {
          upload_id: @upload_status.id,
          app_id: @upload_status.app_id,
          ipa_name: ipa_name,
          ipa_size: ipa_size
        })

        # Step 2: Create build upload and upload file
        @upload_status.transition_to!("uploading")

        build_upload = create_build_upload(
          app_id: @upload_status.app_id,
          cf_bundle_short_version: @upload_status.cf_bundle_short_version,
          cf_bundle_version: @upload_status.cf_bundle_version
        )
        build_upload_id = build_upload.dig("data", "id")
        raise IpaUploadError.new("Failed to create build upload") unless build_upload_id

        @upload_status.update(build_upload_id: build_upload_id)
        log("Created build upload", {build_upload_id: build_upload_id})

        build_upload_file = create_build_upload_file(
          build_upload_id: build_upload_id,
          ipa_name: ipa_name,
          ipa_size: ipa_size
        )
        build_upload_file_id = build_upload_file.dig("data", "id")
        raise IpaUploadError.new("Failed to create build upload file") unless build_upload_file_id

        upload_operations = build_upload_file.dig("data", "attributes", "uploadOperations") || []
        raise IpaUploadError.new("No upload operations found") if upload_operations.empty?

        @upload_status.update(
          build_upload_file_id: build_upload_file_id,
          parts_total: upload_operations.size
        )
        log("Created build upload file", {
          build_upload_file_id: build_upload_file_id,
          parts_count: upload_operations.size
        })

        # Step 3: Upload parts
        upload_parts(ipa_path: ipa_path, upload_operations: upload_operations)
        log("All parts uploaded successfully")

        # Step 4: Commit the upload
        @upload_status.transition_to!("committing")
        commit_upload(build_upload_file_id: build_upload_file_id)
        log("Upload committed successfully")

        # Step 5: Mark as completed
        @upload_status.transition_to!("completed")
        log("Upload completed", {upload_id: @upload_status.id})

        @upload_status
      rescue => e
        log("Upload failed", {upload_id: @upload_status.id, error: e.message})
        @upload_status.fail!(e.message)
        raise
      ensure
        cleanup_temp_file(ipa_path)
      end
    end

    private

    def download_ipa(url)
      log("Downloading IPA from URL", {url: url})

      uri = URI.parse(url)
      temp_dir = File.join(Dir.tmpdir, "applelink_ipa_uploads")
      FileUtils.mkdir_p(temp_dir)

      temp_file = File.join(temp_dir, "#{SecureRandom.uuid}.ipa")

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        request = Net::HTTP::Get.new(uri)

        http.request(request) do |response|
          case response
          when Net::HTTPSuccess
            File.open(temp_file, "wb") do |file|
              response.read_body do |chunk|
                file.write(chunk)
              end
            end
          when Net::HTTPRedirection
            return download_ipa(response["location"])
          else
            raise IpaDownloadError.new("Failed to download IPA: HTTP #{response.code}")
          end
        end
      end

      log("Downloaded IPA", {path: temp_file, size: File.size(temp_file)})
      temp_file
    end

    def create_build_upload(app_id:, cf_bundle_short_version:, cf_bundle_version:)
      body = {
        data: {
          type: "buildUploads",
          attributes: {
            cfBundleShortVersionString: cf_bundle_short_version,
            cfBundleVersion: cf_bundle_version,
            platform: IOS_PLATFORM
          },
          relationships: {
            app: {data: {type: "apps", id: app_id}}
          }
        }
      }

      asc_request(:post, "buildUploads", body)
    end

    def create_build_upload_file(build_upload_id:, ipa_name:, ipa_size:)
      body = {
        data: {
          type: "buildUploadFiles",
          attributes: {
            fileName: ipa_name,
            fileSize: ipa_size,
            assetType: "ASSET",
            uti: "com.apple.ipa"
          },
          relationships: {
            buildUpload: {data: {type: "buildUploads", id: build_upload_id}}
          }
        }
      }

      asc_request(:post, "buildUploadFiles", body)
    end

    def upload_parts(ipa_path:, upload_operations:)
      sorted_operations = upload_operations.sort_by { |op| op["partNumber"] }

      sorted_operations.each do |operation|
        part_number = operation["partNumber"]
        url = operation["url"]
        length = operation["length"]
        offset = operation["offset"]
        request_headers = operation["requestHeaders"] || []

        log("Uploading part", {part_number: part_number, offset: offset, length: length})

        slice_data = File.open(ipa_path, "rb") do |file|
          file.seek(offset)
          file.read(length)
        end

        upload_part_with_retry(
          url: url,
          data: slice_data,
          headers: request_headers,
          part_number: part_number
        )

        @upload_status.increment_parts_uploaded!
      end
    end

    def upload_part_with_retry(url:, data:, headers:, part_number:)
      Retryable.retryable(
        on: [IpaPartUploadError, Net::OpenTimeout, Net::ReadTimeout],
        tries: MAX_RETRIES,
        sleep: ->(n) { n + RETRY_BASE_SLEEP_SECONDS },
        exception_cb: proc { @upload_status.increment_retry_count! }
      ) do
        upload_part(url: url, data: data, headers: headers, part_number: part_number)
      end
    end

    def upload_part(url:, data:, headers:, part_number:)
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 30
      http.read_timeout = PART_UPLOAD_TIMEOUT
      http.max_version = OpenSSL::SSL::TLS1_2_VERSION if http.respond_to?(:max_version=)

      request = Net::HTTP::Put.new(uri)
      request.body = data

      headers.each do |header|
        request[header["name"]] = header["value"]
      end

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise IpaPartUploadError.new("Upload failed for part #{part_number} (HTTP #{response.code}): #{response.body}")
      end

      log("Part uploaded successfully", {part_number: part_number})
    end

    def commit_upload(build_upload_file_id:)
      body = {
        data: {
          type: "buildUploadFiles",
          id: build_upload_file_id,
          attributes: {uploaded: true}
        }
      }

      asc_request(:patch, "buildUploadFiles/#{build_upload_file_id}", body)
    end

    def asc_request(method, endpoint, body = nil)
      uri = URI.parse("#{ASC_API_BASE}/#{endpoint}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 30
      http.read_timeout = 60

      request = case method
      when :get
        Net::HTTP::Get.new(uri)
      when :post
        Net::HTTP::Post.new(uri)
      when :patch
        Net::HTTP::Patch.new(uri)
      end

      request["Authorization"] = "Bearer #{@token.text}"
      request["Content-Type"] = "application/json"

      if body
        request.body = body.to_json
      end

      response = http.request(request)

      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      else
        error_body = begin
          JSON.parse(response.body)
        rescue
          response.body
        end
        log("ASC API error", {endpoint: endpoint, status: response.code, body: error_body})
        raise IpaUploadApiError.new("ASC API error (#{response.code}): #{error_body}")
      end
    end

    def cleanup_temp_file(path)
      return unless path && File.exist?(path)
      File.delete(path)
      log("Cleaned up temp file", {path: path})
    rescue => e
      log("Failed to cleanup temp file", {path: path, error: e.message})
    end

    def log(msg, data = {})
      @logger.debug(msg, data)
    end
  end
end

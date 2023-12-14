require "spaceship"
require "json"
require "ougai"
require "retryable"
require_relative "../../spaceship/wrapper_token"
require_relative "../../spaceship/wrapper_error"

module AppStore
  class Connect
    def self.groups(**params) = new(**params).groups

    def self.build(**params) = new(**params).build(**params.slice(:build_number))

    def self.update_build_notes(**params) = new(**params).update_build_notes(**params.slice(:build_number, :notes))

    def self.latest_build(**params) = new(**params).latest_build

    def self.send_to_group(**params) = new(**params).send_to_group(**params.slice(:group_id, :build_number))

    def self.metadata(**params) = new(**params).metadata

    def self.current_app_info(**params) = new(**params).current_app_info

    def self.prepare_release(**params) = new(**params).prepare_release(**params.slice(:build_number, :is_phased_release, :version, :is_force, :metadata))

    def self.create_review_submission(**params) = new(**params).create_review_submission(**params.slice(:build_number, :version))

    def self.release(**params) = new(**params).release(**params.slice(:build_number))

    def self.start_release(**params) = new(**params).start_release(**params.slice(:build_number))

    def self.live_release(**params) = new(**params).live_release

    def self.pause_phased_release(**params) = new(**params).pause_phased_release

    def self.resume_phased_release(**params) = new(**params).resume_phased_release

    def self.complete_phased_release(**params) = new(**params).complete_phased_release

    def self.halt_release(**params) = new(**params).halt_release

    MAX_RETRIES = 3
    RETRY_BASE_SLEEP_SECONDS = 1
    IOS_PLATFORM = Spaceship::ConnectAPI::Platform::IOS
    VERSION_DATA_INCLUDES = %w[build appStoreVersionPhasedRelease appStoreVersionLocalizations appStoreVersionSubmission].join(",").freeze
    READY_FOR_REVIEW_STATE = "READY_FOR_REVIEW"
    INFLIGHT_RELEASE_FILTERS = {
      appStoreState: [
        Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::PREPARE_FOR_SUBMISSION,
        Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::PROCESSING_FOR_APP_STORE,
        Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::DEVELOPER_REJECTED,
        Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::REJECTED,
        Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::METADATA_REJECTED,
        Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::WAITING_FOR_REVIEW,
        Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::INVALID_BINARY,
        Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::IN_REVIEW,
        Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::PENDING_DEVELOPER_RELEASE,
        Spaceship::ConnectAPI::AppStoreVersion::AppStoreState::PENDING_APPLE_RELEASE,
        READY_FOR_REVIEW_STATE
      ].join(","),
      platform: IOS_PLATFORM
    }

    def initialize(**params)
      token = Spaceship::WrapperToken.new(key_id: params[:key_id], issuer_id: params[:issuer_id], text: params[:token])
      Spaceship::ConnectAPI.token = token
      @api = Spaceship::ConnectAPI
      @bundle_id = params[:bundle_id]
      @logger = ::Ougai::Logger.new($stdout)
    end

    attr_reader :api, :bundle_id

    def app
      @app ||= api::App.find(bundle_id)
      raise AppNotFoundError unless @app
      @app
    end

    # no of api calls: 3 + n (n = number of beta groups)
    def current_app_info
      beta_app_info.push({name: "production", builds: [live_app_info, inflight_release_info].compact})
    end

    # no of api calls: 1 + n (n = number of beta groups)
    def beta_app_info
      app.get_beta_groups(filter: {isInternalGroup: false}).map do |group|
        builds = get_builds_for_group(group.id).map do |build|
          build_data(build)
            .slice(:id, :build_number, :beta_external_state, :version_string, :uploaded_date)
            .transform_keys({beta_external_state: :status, uploaded_date: :release_date})
        end

        {name: group.name, builds: builds}
      end
    end

    # no of api calls: 2
    def groups
      app.get_beta_groups.map do |group|
        {name: group.name, id: group.id, internal: group.is_internal_group}
      end
    end

    # no of api calls: 2;  +3 retries
    def build(build_number:)
      build_data(get_build(build_number))
    end

    def update_build_notes(build_number:, notes: nil)
      return if notes.nil? || notes.empty?
      execute do
        build = get_build(build_number, %w[betaBuildLocalizations])
        locale = build.get_beta_build_localizations.first
        locale_params = {whatsNew: notes}

        log "Updating locale for the build", {build: build.to_json, locale: locale, params: locale_params}

        if locale
          api.patch_beta_build_localizations(localization_id: locale.id, attributes: locale_params)
        else
          attributes[:locale] = "en-US"
          api.post_beta_build_localizations(build_id: build.id, attributes: locale_params)
        end
      end
    end

    # no of api calls: 2
    def latest_build
      build = app.get_builds(includes: "preReleaseVersion,buildBetaDetail", sort: "-version").first
      raise BuildNotFoundError.new("No build found for the app") unless build
      build_data(build)
    end

    # no of api calls: 4-7
    def send_to_group(group_id:, build_number:)
      execute do
        # NOTE: have to get the build separately, can not be included in the app
        # That inclusion is not exposed by Spaceship, but it does exist in apple API, so it can be fixed later
        # Only two includes in app are: appStoreVersions and prices
        build = get_build(build_number)
        # NOTE: same as above
        group = group(group_id)
        build = update_export_compliance(build)

        submit_for_beta_review(build) unless group.is_internal_group
        build.add_beta_groups(beta_groups: [group])
      end
    end

    # no of api calls: 1
    def metadata
      {
        id: app.id,
        name: app.name,
        bundle_id: app.bundle_id,
        sku: app.sku
      }
    end

    # no of api calls: 6-10
    def prepare_release(build_number:, version:, is_phased_release:, metadata:, is_force: false)
      execute do
        build = get_build(build_number)
        update_export_compliance(build)

        log "Ensure an editable app store version", {version: version, build: build.version}
        latest_version = ensure_editable_version(is_force)

        if latest_version
          log "There is an editable app store version, updating the details", {app_store_version: latest_version.to_json, version: version, build: build.version}
          update_version_details!(latest_version, version, build)
        else
          log "There is no editable app store version, creating it", {version: version, build: build.version}
          latest_version = create_app_store_version(version, build)
        end

        locale = latest_version.app_store_version_localizations.first
        locale_params = if metadata[:whats_new].nil? || metadata[:whats_new].empty?
          {"whatsNew" => "The latest version contains bug fixes and performance improvements."}
        else
          {"whatsNew" => metadata[:whats_new]}
        end

        unless metadata[:promotional_text].nil? || metadata[:promotional_text].empty?
          locale_params["promotionalText"] = metadata[:promotional_text]
        end

        log "Updating locale for the app store version", {locale: locale.to_json, params: locale_params}
        locale.update(attributes: locale_params)

        if is_phased_release && latest_version.app_store_version_phased_release.nil?
          log "Creating phased release for the app store version"
          latest_version.create_app_store_version_phased_release(attributes: {
            phasedReleaseState: api::AppStoreVersionPhasedRelease::PhasedReleaseState::INACTIVE
          })
        elsif !is_phased_release && latest_version.app_store_version_phased_release
          log "Removing phased release from the app store version"
          latest_version.app_store_version_phased_release.delete!
        end

        version_data(app.get_edit_app_store_version(includes: VERSION_DATA_INCLUDES))
      end
    end

    # no of api calls: 8-9
    def create_review_submission(build_number:, version: nil)
      execute do
        build = get_build(build_number)

        edit_version = app
          .get_app_store_versions(includes: "build", filter: INFLIGHT_RELEASE_FILTERS)
          .find { |v| v.build&.version == build_number.to_s }
        raise VersionNotFoundError unless edit_version

        ensure_correct_build(build, edit_version)
        if edit_version.version_string != version
          edit_version.update(attributes: {versionString: version})
        end

        if app.get_in_progress_review_submission(platform: IOS_PLATFORM)
          raise ReviewAlreadyInProgressError
        end

        submission = app.get_ready_review_submission(platform: IOS_PLATFORM, includes: "items")

        raise SubmissionWithItemsExistError if submission && !submission.items.empty?

        submission ||= app.create_review_submission(platform: IOS_PLATFORM)

        submission.add_app_store_version_to_review_items(app_store_version_id: edit_version.id)

        submit_review(submission, edit_version)
      end
    end

    def submit_review(submission, edit_version)
      execute_with_retry(AppStore::InvalidReviewStateError) do
        log("Submitting app #{edit_version.version_string} for review")
        submission.submit_for_review
      end
    end

    # no of api calls: 2
    def release(build_number: nil)
      execute do
        if build_number.nil? || build_number.empty?
          version = current_inflight_release

          raise VersionNotFoundError.new("No inflight release found") unless version
        else
          version = app.get_app_store_versions(includes: VERSION_DATA_INCLUDES, filter: INFLIGHT_RELEASE_FILTERS)
            .find { |v| v.build&.version == build_number }

          raise VersionNotFoundError.new("No release found for the build number - #{build_number}") unless version
        end
        version_data(version)
      end
    end

    # no of api calls: 2
    def start_release(build_number:)
      execute do
        filter = {
          appStoreState: [
            api::AppStoreVersion::AppStoreState::PENDING_DEVELOPER_RELEASE
          ].join(","),
          platform: IOS_PLATFORM
        }
        edit_version = app.get_app_store_versions(includes: "build", filter: filter)
          .find { |v| v.build&.version == build_number }

        raise VersionNotFoundError.new("No startable release found for the build number - #{build_number}") unless edit_version

        edit_version.create_app_store_version_release_request
      end
    end

    # no of api calls: 3
    def pause_phased_release
      execute do
        live_version = app.get_live_app_store_version(includes: VERSION_DATA_INCLUDES)
        raise PhasedReleaseNotFoundError unless live_version.app_store_version_phased_release

        ensure_release_editable(live_version)
        updated_phased_release = live_version.app_store_version_phased_release.pause
        live_version.app_store_version_phased_release = updated_phased_release
        version_data(live_version)
      end
    end

    # no of api calls: 3
    def resume_phased_release
      execute do
        live_version = app.get_live_app_store_version(includes: VERSION_DATA_INCLUDES)
        raise PhasedReleaseNotFoundError unless live_version.app_store_version_phased_release

        ensure_release_editable(live_version)
        updated_phased_release = live_version.app_store_version_phased_release.resume
        live_version.app_store_version_phased_release = updated_phased_release
        version_data(live_version)
      end
    end

    # no of api calls: 3
    def complete_phased_release
      execute do
        live_version = app.get_live_app_store_version(includes: VERSION_DATA_INCLUDES)
        raise PhasedReleaseNotFoundError unless live_version.app_store_version_phased_release
        updated_phased_release = live_version.app_store_version_phased_release.complete
        live_version.app_store_version_phased_release = updated_phased_release
        version_data(live_version)
      end
    end

    # no of api calls: 3
    def halt_release
      execute do
        live_version = app.get_live_app_store_version
        if live_version.app_store_state == api::AppStoreVersion::AppStoreState::DEVELOPER_REMOVED_FROM_SALE
          raise ReleaseAlreadyHaltedError
        end

        body = {
          data: {
            type: "appAvailabilities",
            attributes: {availableInNewTerritories: false},
            relationships: {
              app: {data: {type: "apps",
                           id: app.id}},
              availableTerritories: {data: []}
            }
          }
        }

        api.test_flight_request_client.post("appAvailabilities", body)
      end
    end

    # no of api calls: 2
    def live_release
      execute do
        live_version = app.get_live_app_store_version(includes: VERSION_DATA_INCLUDES)
        raise VersionNotFoundError.new("No release live yet.") unless live_version
        version_data(live_version)
      end
    end

    private

    def current_inflight_release
      app.get_app_store_versions(includes: VERSION_DATA_INCLUDES, filter: INFLIGHT_RELEASE_FILTERS)
        .max_by { |v| Date.parse(v.created_date) }
    end

    def inflight_release_info
      inflight_version = current_inflight_release
      return unless inflight_version
      {
        id: inflight_version.id,
        version_string: inflight_version.version_string,
        status: inflight_version.app_store_state,
        release_date: inflight_version.created_date,
        build_number: inflight_version.build&.version
      }
    end

    # no of api calls: 2
    def live_app_info
      live_version = app.get_live_app_store_version
      return unless live_version
      {
        id: live_version.id,
        version_string: live_version.version_string,
        status: live_version.app_store_state,
        release_date: live_version.created_date,
        build_number: live_version.build&.version
      }
    end

    # no of api calls: 1-4 ; +3 with every retry attempt
    def submit_for_beta_review(build)
      retry_proc = proc do
        log("Retrying submitting for beta review.")
        waiting_for_review_build = app.get_builds(
          filter: {"betaAppReviewSubmission.betaReviewState" => "WAITING_FOR_REVIEW,IN_REVIEW",
                   "expired" => false,
                   "preReleaseVersion.version" => build.pre_release_version.version}
        ).first
        if waiting_for_review_build
          waiting_for_review_build.expire!
          log("Expired build - #{waiting_for_review_build.version}.")
        end
      end

      execute_with_retry(AppStore::ReviewAlreadyInProgressError, retry_proc:) do
        log("Submitting beta build for review")
        build.post_beta_app_review_submission if build.ready_for_beta_submission?
      end
    end

    def get_latest_app_store_version
      filter = {
        platform: IOS_PLATFORM
      }
      app.get_app_store_versions(includes: VERSION_DATA_INCLUDES, filter:).max_by { |v| Time.parse(v.created_date) }
    end

    # no of api calls: 1-3
    def ensure_editable_version(is_force)
      latest_version = get_latest_app_store_version

      log "Latest app store version", latest_version.to_json

      case latest_version.app_store_state
      when api::AppStoreVersion::AppStoreState::READY_FOR_SALE,
        api::AppStoreVersion::AppStoreState::DEVELOPER_REMOVED_FROM_SALE

        log "Found a live app store version", latest_version.to_json
        return

      when api::AppStoreVersion::AppStoreState::REJECTED
        log "Found rejected app store version", latest_version.to_json
        raise VersionAlreadyAddedToSubmissionError unless is_force

        submission = app.get_in_progress_review_submission(platform: IOS_PLATFORM)
        log "Deleting rejected app store version submission", submission.to_json
        submission.cancel_submission
        return

      when api::AppStoreVersion::AppStoreState::PENDING_DEVELOPER_RELEASE,
        api::AppStoreVersion::AppStoreState::PENDING_APPLE_RELEASE,
        api::AppStoreVersion::AppStoreState::WAITING_FOR_REVIEW,
        api::AppStoreVersion::AppStoreState::IN_REVIEW

        log "Found releasable app store version", latest_version.to_json
        raise VersionAlreadyAddedToSubmissionError unless is_force
        # NOTE: Apple has deprecated this API, but even the appstore connect dashboard uses the deprecated API to do this action
        # https://developer.apple.com/documentation/appstoreconnectapi/delete_an_app_store_version_submission
        log "Cancelling the release for releasable app store version", latest_version.to_json
        latest_version.app_store_version_submission.delete!

      when api::AppStoreVersion::AppStoreState::PREPARE_FOR_SUBMISSION,
        api::AppStoreVersion::AppStoreState::DEVELOPER_REJECTED

        log "Found draft app store version", latest_version.to_json
        raise VersionAlreadyAddedToSubmissionError unless is_force
      end

      latest_version
    end

    # no of api calls: 2
    def create_app_store_version(version, build)
      data = build_app_store_version_attributes(version, build)
      data[:relationships][:app] = {data: {type: "apps", id: app.id}}
      data[:attributes][:platform] = IOS_PLATFORM
      body = {data: data}

      log "Creating app store version with ", {body: body}
      api.tunes_request_client.post("appStoreVersions", body)
      execute_with_retry(AppStore::VersionNotFoundError, sleep_seconds: 15, max_retries: 10) do
        log("Fetching the created app store version")
        inflight_version = app.get_edit_app_store_version(includes: VERSION_DATA_INCLUDES)
        raise VersionNotFoundError unless inflight_version
        inflight_version
      end
    end

    # no of api calls: 1
    def update_version_details!(app_store_version, version, build)
      attempts ||= 1
      execute do
        body = {
          data: {
            id: app_store_version.id
          }.merge(build_app_store_version_attributes(version, build, app_store_version))
        }

        log "Updating app store version details with ", {body: body, attempts: attempts}
        api.tunes_request_client.patch("appStoreVersions/#{app_store_version.id}", body)

        app_store_version
      end
    rescue VersionNotEditableError => e
      if attempts <= 3
        attempts += 1
        sleep attempts
        retry
      else
        Sentry.capture_exception(e)
        raise e
      end
    end

    def build_app_store_version_attributes(version, build, app_store_version = nil)
      # Updating version to be released manually by tramline, not automatically after approval
      attributes = {releaseType: "MANUAL"}
      relationships = nil

      if version != app_store_version&.version_string
        attributes[:versionString] = version
      end

      if app_store_version&.build&.id != build.id
        relationships = {
          build: {
            data: {
              type: "builds",
              id: build.id
            }
          }
        }
      end

      body = {
        type: "appStoreVersions",
        attributes: attributes,
        relationships: (relationships unless relationships.nil?)
      }
      body.compact!
      body
    end

    def ensure_correct_build(build, version)
      raise BuildMismatchError if version.build.version != build.version
    end

    def ensure_release_editable(version)
      if version.app_store_version_phased_release.phased_release_state == api::AppStoreVersionPhasedRelease::PhasedReleaseState::COMPLETE
        raise ReleaseNotEditableError
      end
    end

    def version_data(version)
      {
        id: version.id,
        version_name: version.version_string,
        app_store_state: version.app_store_state,
        release_type: version.release_type,
        earliest_release_date: version.earliest_release_date,
        downloadable: version.downloadable,
        created_date: version.created_date,
        build_number: version.build&.version,
        build_id: version.build&.id,
        build_created_at: version.build&.uploaded_date,
        phased_release: version.app_store_version_phased_release,
        details: version.app_store_version_localizations&.first,
        added_at: [version.created_date, version.build&.uploaded_date].compact.max
      }
    end

    def get_builds_for_group(group_id, limit = 2)
      api.get_builds(
        filter: {app: app.id,
                 betaGroups: group_id,
                 expired: "false"},
        sort: "-uploadedDate",
        includes: "buildBetaDetail,preReleaseVersion",
        limit: limit
      )
    end

    def build_data(build)
      {
        id: build.id,
        build_number: build.version,
        beta_internal_state: build.build_beta_detail&.internal_build_state,
        beta_external_state: build.build_beta_detail&.external_build_state,
        uploaded_date: build.uploaded_date,
        expired: build.expired,
        processing_state: build.processing_state,
        version_string: build.pre_release_version&.version
      }
    end

    def update_export_compliance(build)
      execute do
        return build unless build.missing_export_compliance?

        api.patch_builds(build_id: build.id, attributes: {usesNonExemptEncryption: false})
        updated_build = api::Build.get(build_id: build.id)
        raise ExportComplianceNotFoundError if updated_build.missing_export_compliance?
        updated_build
      end
    rescue ExportComplianceAlreadyUpdatedError => e
      Sentry.capture_exception(e)
      build
    end

    def group(id)
      group = app.get_beta_groups(filter: {id:}).first
      raise BetaGroupNotFoundError.new("Beta group with id #{id} not found") unless group
      group
    end

    def get_build(build_number, includes = [])
      execute_with_retry(BuildNotFoundError) do
        log "Fetching build with build number #{build_number}"
        build = app.get_builds(includes: %w[preReleaseVersion buildBetaDetail].concat(includes).join(","), filter: {version: build_number}).first
        log("Found build with build number #{build_number}", build.to_json) if build
        raise BuildNotFoundError.new("Build with number #{build_number} not found") unless build_ready?(build)
        build
      end
    end

    def build_ready?(build)
      build&.processed? && build&.build_beta_detail
    end

    def execute
      yield
    rescue Spaceship::UnexpectedResponse => e
      raise Spaceship::WrapperError.handle(e)
    end

    def execute_with_retry(exception_type, retry_proc: proc {}, sleep_seconds: RETRY_BASE_SLEEP_SECONDS, max_retries: MAX_RETRIES)
      Retryable.retryable(on: [exception_type], tries: max_retries, sleep: ->(n) { n + sleep_seconds }, exception_cb: retry_proc) do
        execute { yield }
      end
    end

    def log(msg, data = {})
      @logger.debug(msg, data)
    end
  end
end

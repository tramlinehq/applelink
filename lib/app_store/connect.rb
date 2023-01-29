require "spaceship"
require "json"
require_relative "../../spaceship/wrapper_token"

module AppStore
  class Connect
    def self.groups(**params) = new(**params).groups(**params.slice(:internal))

    def self.build(**params) = new(**params).build(**params.slice(:build_number))

    def self.send_to_group(**params) = new(**params).send_to_group(**params.slice(:group_id, :build_number))

    def self.metadata(**params) = new(**params).metadata

    def self.versions(**params) = new(**params).versions

    def initialize(**params)
      token = Spaceship::WrapperToken.new(key_id: params[:key_id], issuer_id: params[:issuer_id], text: params[:token])
      Spaceship::ConnectAPI.token = token
      @api = Spaceship::ConnectAPI
      @bundle_id = params[:bundle_id]
    end

    attr_reader :api, :bundle_id

    def app
      @app ||=
        api::App.find(bundle_id)
    end

    # no of api calls: 2
    def groups(internal:)
      app.get_beta_groups(includes: "betaTesters", filter: {isInternalGroup: to_bool(internal)}).map do |group|
        testers =
          group.beta_testers.map do |tester|
            {
              name: "#{tester.first_name} #{tester.last_name}",
              email: tester.email
            }
          end

        {name: group.name, id: group.id, internal: group.is_internal_group, testers: testers}
      end
    end

    # no of api calls: 2
    # FIXME: fail unless "processing_state": "VALID"
    def build(build_number:)
      get_build(build_number)
        &.then do |build|
        {
          build_number: build.version,
          beta_internal_state: build.build_beta_detail.internal_build_state,
          beta_external_state: build.build_beta_detail.external_build_state,
          uploaded_date: build.uploaded_date,
          expired: build.expired,
          processing_state: build.processing_state,
          version_string: build.pre_release_version.version
        }
      end
    end

    # Build beta external state
    # PROCESSING
    # PROCESSING_EXCEPTION
    # MISSING_EXPORT_COMPLIANCE
    # READY_FOR_BETA_TESTING -- it was before submission
    # IN_BETA_TESTING
    # EXPIRED
    # READY_FOR_BETA_SUBMISSION
    # IN_EXPORT_COMPLIANCE_REVIEW
    # WAITING_FOR_BETA_REVIEW -- state when it has been submitted to apple for review
    # IN_BETA_REVIEW -- state when they have picked up apple review
    # BETA_REJECTED
    # BETA_APPROVED

    # no of api calls: 5-7
    def send_to_group(group_id:, build_number:)
      raise AppNotFoundError unless app

      build = get_build(build_number)
      raise BuildNotFoundError.new("Build with number #{build_number} not found") unless build

      group = group(group_id)
      raise BetaGroupNotFoundError.new("Beta group with id #{group_id} not found") unless group

      if build.missing_export_compliance?
        # FIXME: handle 'Spaceship::UnexpectedResponse: The provided entity includes an attribute with an invalid value - You cannot update when the value is already set.'
        api.patch_builds(build_id: build.id, attributes: {usesNonExemptEncryption: false})
        build = api::Build.get(build_id: build.id)
      end

      raise ExportComplianceNotFoundError if build.missing_export_compliance?

      build.post_beta_app_review_submission if build.ready_for_beta_submission? && !group.is_internal_group
      build.add_beta_groups(beta_groups: [group])
    end

    # no of api calls: 1
    def metadata
      raise AppNotFoundError unless app

      {
        id: app.id,
        name: app.name,
        bundle_id: app.bundle_id,
        sku: app.sku
      }
    end

    # no of api calls: 2
    def versions
      app.get_app_store_versions.map do |app_version|
        {
          version_name: app_version.version_string,
          app_store_state: app_version.app_store_state,
          release_type: app_version.release_type,
          earliest_release_date: app_version.earliest_release_date,
          downloadable: app_version.downloadable,
          created_date: app_version.created_date,
          build_number: app_version.build&.version
        }
      end
    end

    private

    def group(id)
      app.get_beta_groups(filter: {id:}).first
    end

    def get_build(build_number)
      app.get_builds(includes: "preReleaseVersion,buildBetaDetail", filter: {version: build_number}).first
    end

    def to_bool(s)
      case s.downcase.strip
      when "true", "yes", "on", "t", "1", "y", "=="
        true
      when "nil", "null"
        nil
      else
        false
      end
    end
  end
end

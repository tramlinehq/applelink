require "spaceship"
require "json"
require_relative "../../spaceship/wrapper_token"

module AppStore
  class Connect
    def initialize(bundle_id, key_id:, issuer_id:, token:)
      token = Spaceship::WrapperToken.new(key_id:, issuer_id:, text: token)

      Spaceship::ConnectAPI.token = token

      @api = Spaceship::ConnectAPI
      @bundle_id = bundle_id
    end

    attr_reader :api, :bundle_id

    def app
      @app ||=
        api::App.find(bundle_id)
    end

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

    def build(v)
      get_build(v)
        &.then do |build|
        {
          build_number: build.version,
          details: build.get_build_beta_details,
          uploaded_date: build.uploaded_date,
          expired: build.expired,
          processing_state: build.processing_state,
          version_string: build.pre_release_version
        }
      end
    end

    def add_build_to_group(group_id:, build_number:)
      raise AppNotFoundError unless app

      build = get_build(build_number)
      raise BuildNotFoundError.new("Build with number #{build_number} not found") unless build

      group = group(group_id)
      raise BetaGroupNotFoundError.new("Beta group with id #{group_id} not found") unless group

      build_with_details = api::Build.get(build_id: build.id)

      build_with_details.post_beta_app_review_submission if build_with_details.ready_for_beta_submission? && !group.is_internal_group
      build_with_details.add_beta_groups(beta_groups: [group])
    end

    def metadata
      raise AppNotFoundError unless app
      {
        id: app.id,
        name: app.name,
        bundle_id: app.bundle_id,
        sku: app.sku
      }
    end

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
      app.get_builds(includes: "preReleaseVersion", filter: {version: build_number}).first
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

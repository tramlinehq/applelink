require "spaceship"
require "json"
require "./spaceship/wrapper_token"

class AppStore
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
    app.get_beta_groups(includes: "betaTesters", filter: { isInternalGroup: to_bool(internal) }).map do |group|
      testers =
        group.beta_testers.map do |tester|
          {
            name: "#{tester.first_name} #{tester.last_name}",
            email: tester.email
          }
        end

      [{ name: group.name, internal: group.is_internal_group, testers: testers }]
    end
  end

  def builds(v)
    app.get_builds(includes: "preReleaseVersion", filter: { version: v }).map do |build|
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

  def metadata
    return unless app
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
        build_number: app_version.build.nil? ? nil : app_version.build.version
      }
    end
  end

  private

  def to_bool(s)
    case s.downcase.strip
    when 'true', 'yes', 'on', 't', '1', 'y', '=='
      return true
    when 'nil', 'null'
      return nil
    else
      return false
    end
  end
end

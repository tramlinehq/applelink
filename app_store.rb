require "spaceship"
require "json"

class AppStore
  def initialize(bundle_id)
    token = Spaceship::ConnectAPI::Token.create(
      key_id: "2NK99Z483A",
      issuer_id: "54df29f3-21e4-4336-a67a-c1d738af5e80",
      filepath: File.absolute_path("key.p8")
    )

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

      [{ name: group.name, internal: group.is_internal_group, testers: testers}]
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

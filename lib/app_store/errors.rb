module AppStore
  def self.error_as_json(resource, code, message = "")
    {
      "resource" => resource.to_s,
      "code" => code.to_s,
      "message" => (message unless message.empty?)
    }.compact
  end

  class AppNotFoundError < StandardError
    def initialize(msg = "App not found")
      super
    end

    def as_json
      AppStore.error_as_json(:app, :not_found)
    end
  end

  class BuildNotFoundError < StandardError
    def as_json
      AppStore.error_as_json(:build, :not_found)
    end
  end

  class BetaGroupNotFoundError < StandardError
    def as_json
      AppStore.error_as_json(:beta_group, :not_found)
    end
  end

  class ExportComplianceNotFoundError < StandardError
    MSG = "Could not update missing export compliance attribute for the build."

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:build, :export_compliance_not_updateable, MSG)
    end
  end

  class BuildSubmissionForReviewNotAllowedError < StandardError
    def as_json
      AppStore.error_as_json(:release, :review_submission_not_allowed)
    end
  end

  class ExportComplianceAlreadyUpdatedError < StandardError; end

  class VersionNotFoundError < StandardError
    MSG = "No app store version found to distribute"

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :not_found, MSG)
    end
  end

  class BuildMismatchError < StandardError
    MSG = "The build on the release in app store does not match the build number"

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :build_mismatch, MSG)
    end
  end

  class ReviewAlreadyInProgressError < StandardError
    MSG = "There is a review already in progress, can not submit a new review to store"

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :review_in_progress)
    end
  end

  class SubmissionWithItemsExistError < StandardError
    MSG = "Cannot submit for review - a review submission already exists with items"

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :review_already_created, MSG)
    end
  end

  class PhasedReleaseAlreadyInStateError < StandardError; end

  class PhasedReleaseNotFoundError < StandardError
    MSG = "The current live release does not have a staged rollout"

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :phased_release_not_found, MSG)
    end
  end

  class AppAlreadyHaltedError < StandardError
    def initialize(msg = "The app is already removed from sale for the latest version.")
      super
    end
  end

  class VersionAlreadyAddedToSubmissionError < StandardError
    MSG = "There is already an app store version in submission, can not start another release preparation"

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :release_already_prepared, MSG)
    end
  end

  NOT_FOUND_ERRORS = [
    AppStore::AppNotFoundError,
    AppStore::BuildNotFoundError,
    AppStore::BetaGroupNotFoundError
  ]

  ERRORS = [
    AppStore::ExportComplianceNotFoundError,
    AppStore::BuildSubmissionForReviewNotAllowedError,
    AppStore::VersionNotFoundError,
    AppStore::ReviewAlreadyInProgressError,
    AppStore::AppAlreadyHaltedError,
    AppStore::SubmissionWithItemsExistError,
    AppStore::BuildMismatchError,
    AppStore::VersionAlreadyAddedToSubmissionError
  ]

  CONFLICT_ERRORS = [AppStore::PhasedReleaseAlreadyInStateError]
end

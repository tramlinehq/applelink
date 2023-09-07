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

  class InvalidReviewStateError < StandardError
    MSG = "The app store version is not in a valid state to submit for review"

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

  class PhasedReleaseAlreadyInStateError < StandardError
    MSG = "The current live release is already in the state you are requesting"

    def as_json
      AppStore.error_as_json(:release, :release_already_in_state, MSG)
    end
  end

  class PhasedReleaseNotFoundError < StandardError
    MSG = "The current live release does not have a staged rollout"

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :phased_release_not_found, MSG)
    end
  end

  class ReleaseAlreadyHaltedError < StandardError
    MSG = "The release is already removed from sale for the latest version."

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :release_already_halted, MSG)
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

  class VersionAlreadyExistsError < StandardError
    MSG = "The build number has been previously used for a release"

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :version_already_exists, MSG)
    end
  end

  class ReleaseNotEditableError < StandardError
    MSG = "The release is now fully live and can not be updated"

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :release_fully_live, MSG)
    end
  end

  class UnexpectedAppstoreError < StandardError
    def as_json
      AppStore.error_as_json(:unknown, :unknown, message)
    end
  end

  class VersionNotEditableError < StandardError
    MSG = "The release is not editable in its current state"

    def initialize(msg = MSG)
      super
    end

    def as_json
      AppStore.error_as_json(:release, :release_not_editable, MSG)
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
    AppStore::SubmissionWithItemsExistError,
    AppStore::BuildMismatchError,
    AppStore::VersionAlreadyAddedToSubmissionError,
    AppStore::VersionAlreadyExistsError,
    AppStore::UnexpectedAppstoreError,
    AppStore::VersionNotEditableError
  ]

  CONFLICT_ERRORS = [AppStore::PhasedReleaseAlreadyInStateError, AppStore::ReleaseNotEditableError, AppStore::ReleaseAlreadyHaltedError]
end

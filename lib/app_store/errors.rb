module AppStore
  class AppNotFoundError < StandardError
    def initialize(msg = "App not found")
      super
    end
  end

  class BuildNotFoundError < StandardError
    def initialize(msg = "Build not found")
      super
    end
  end

  class BetaGroupNotFoundError < StandardError
    def initialize(msg = "Beta group not found")
      super
    end
  end

  class ExportComplianceNotFoundError < StandardError
    def initialize(msg = "Missing export compliance attribute for the build.")
      super
    end
  end

  class BuildSubmissionForReviewNotAllowedError < StandardError; end

  class ExportComplianceAlreadyUpdatedError < StandardError; end

  class EditVersionNotFoundError < StandardError
    def initialize(msg = "No app store version found to distribute")
      super
    end
  end

  class ReviewAlreadyInProgressError < StandardError
    def initialize(msg = "There is a review already in progress, can not submit a new review to store.")
      super
    end
  end

  class PhasedReleaseAlreadyInStateError < StandardError; end

  class PhasedReleaseNotFoundError < StandardError
    def initialize(msg = "The current live release does not have a staged rollout.")
      super
    end
  end

  class AppAlreadyHaltedError < StandardError
    def initialize(msg = "The app is already removed from sale for the latest version.")
      super
    end
  end

  NOT_FOUND_ERRORS = [AppStore::AppNotFoundError,
    AppStore::BuildNotFoundError,
    AppStore::BetaGroupNotFoundError]

  ERRORS = [AppStore::ExportComplianceNotFoundError,
    AppStore::BuildSubmissionForReviewNotAllowedError,
    AppStore::EditVersionNotFoundError,
    AppStore::ReviewAlreadyInProgressError]

  CONFLICT_ERRORS = [AppStore::PhasedReleaseAlreadyInStateError]
end

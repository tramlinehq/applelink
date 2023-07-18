module Spaceship
  class WrapperError
    MESSAGES = [
      {
        message_matcher: /The build is not in a valid processing state for this operation/,
        decorated_exception: AppStore::BuildSubmissionForReviewNotAllowedError
      },
      {
        message_matcher: /You cannot update when the value is already set. - \/data\/attributes\/usesNonExemptEncryption/,
        decorated_exception: AppStore::ExportComplianceAlreadyUpdatedError
      },
      {
        message_matcher: /The phased release already has this value - \/data\/attributes\/phasedReleaseState/,
        decorated_exception: AppStore::PhasedReleaseAlreadyInStateError
      },
      {
        message_matcher: /You cannot create a new version of the App in the current state/,
        decorated_exception: AppStore::VersionAlreadyAddedToSubmissionError
      },
      {
        message_matcher: /The version number has been previously used. - \/data\/attributes\/versionString/,
        decorated_exception: AppStore::VersionAlreadyExistsError
      },
      {
        message_matcher: /An attribute value is not acceptable for the current resource state. - The attribute 'versionString' can not be modified. - \/data\/attributes\/versionString/,
        decorated_exception: AppStore::VersionNotEditableError
      },
      {
        message_matcher: /A relationship value is not acceptable for the current resource state. - The specified pre-release build could not be added. - \/data\/relationships\/build/,
        decorated_exception: AppStore::VersionNotEditableError
      },
      {
        message_matcher: /Another build is in review/,
        decorated_exception: AppStore::ReviewAlreadyInProgressError
      }
    ]

    def self.handle(exception)
      new(exception).handle
    end

    def initialize(exception)
      @exception = exception
    end

    def handle
      return AppStore::UnexpectedAppstoreError.new(exception) if match.nil?
      match[:decorated_exception].new message
    end

    private

    attr_reader :exception

    def match
      @match ||= matched_message
    end

    def matched_message
      MESSAGES.find { |known_error_message| known_error_message[:message_matcher] =~ message }
    end

    def message
      exception.message
    end
  end
end

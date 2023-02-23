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
        message_matcher: /Resource reviewSubmissions with id (.*) cannot be found/,
        decorated_exception: AppStore::SubmissionNotFoundError
      }
    ]

    def self.handle(exception)
      new(exception).handle
    end

    def initialize(exception)
      @exception = exception
    end

    def handle
      return exception if match.nil?
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

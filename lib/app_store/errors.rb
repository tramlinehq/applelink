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

  ERRORS = [AppStore::AppNotFoundError,
            AppStore::BuildNotFoundError,
            AppStore::BetaGroupNotFoundError]
end

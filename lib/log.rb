require "dry/logger"

module Logger
  $logger = Dry.Logger(:applelink, template: :details).add_backend(formatter: :rack)
end

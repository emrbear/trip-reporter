module TripReporter
  VERSION = '1.1.0'

  class OverlayError < StandardError; end

  class FillError < StandardError; end
end

require_relative 'trip_reporter/ahcccs'
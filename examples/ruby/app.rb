# Ruby example - Weather data processor with metaprogramming
require "json"
require "net/http"
require "date"
require "forwardable"

# ---------- Module with mixin ----------

module Validatable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def validates(*attrs, presence: false, type: nil)
      @validations ||= []
      @validations << { attrs: attrs, presence: presence, type: type }
    end

    def validations
      @validations || []
    end
  end

  def valid?
    self.class.validations.all? do |validation|
      validation[:attrs].all? do |attr|
        value = send(attr)
        next false if validation[:presence] && value.nil?
        next false if validation[:type] && !value.is_a?(validation[:type])
        true
      end
    end
  end
end

# ---------- Data Classes ----------

class WeatherReading
  include Validatable

  attr_reader :temperature, :humidity, :pressure, :timestamp, :location

  validates :temperature, :humidity, :pressure, presence: true
  validates :temperature, :humidity, :pressure, type: Numeric

  def initialize(temperature:, humidity:, pressure:, location:, timestamp: Time.now)
    @temperature = temperature
    @humidity = humidity
    @pressure = pressure
    @location = location
    @timestamp = timestamp
  end

  def to_fahrenheit
    (temperature * 9.0 / 5.0) + 32.0
  end

  def to_s
    "[#{timestamp.strftime("%H:%M")}] #{location}: #{temperature}°C / #{humidity}%"
  end
end

class Forecast
  using(Module.new do
    refine Numeric do
      def celsius_to_fahrenheit
        self * 9.0 / 5.0 + 32.0
      end
    end
  end)

  attr_reader :readings

  def initialize(readings = [])
    @readings = readings
  end

  def add(reading)
    @readings << reading
  end

  def average_temperature
    return 0.0 if @readings.empty?
    @readings.map(&:temperature).sum / @readings.size
  end

  def max_temperature
    @readings.map(&:temperature).max
  end

  def by_location(location)
    @readings.select { |r| r.location == location }
  end

  def summary
    {
      avg_temp: average_temperature.round(1),
      max_temp: max_temperature,
      min_temp: @readings.map(&:temperature).min,
      avg_humidity: @readings.map(&:humidity).sum / @readings.size,
      readings_count: @readings.size
    }
  end
end

# ---------- Service Object ----------

class WeatherService
  BASE_URL = "https://api.open-meteo.com/v1/forecast"

  Location = Data.define(:name, :latitude, :longitude)

  LOCATIONS = [
    Location.new("São Paulo", -23.5505, -46.6333),
    Location.new("Rio de Janeiro", -22.9068, -43.1729),
    Location.new("Belo Horizonte", -19.9167, -43.9345)
  ]

  def initialize(http_client: nil)
    @http_client = http_client || Net::HTTP
  end

  def fetch_all
    LOCATIONS.map { |location| fetch_location(location) }
  end

  private

  def fetch_location(location)
    uri = build_uri(location)
    response = @http_client.get_response(uri)

    raise "API error: #{response.code}" unless response.is_a?(Net::HTTPOK)

    data = JSON.parse(response.body)
    parse_response(data, location)
  rescue StandardError => e
    puts "[ERROR] Failed to fetch #{location.name}: #{e.message}"
    nil
  end

  def build_uri(location)
    URI("#{BASE_URL}?#{URI.encode_www_form(
      latitude: location.latitude,
      longitude: location.longitude,
      current_weather: true
    )}")
  end

  def parse_response(data, location)
    current = data["current_weather"]
    WeatherReading.new(
      temperature: current["temperature"],
      humidity: current["temperature"],  # simplified
      pressure: 1013.0,  # simplified
      location: location.name,
      timestamp: Time.parse(current["time"])
    )
  end
end

# ---------- Decorator ----------

class ReadingDecorator
  extend Forwardable

  def_delegators :@reading, :temperature, :humidity, :pressure, :location, :timestamp

  def initialize(reading)
    @reading = reading
  end

  def formatted
    <<~TEXT
      ┌─────────────────────┐
      │ #{location.ljust(19)} │
      │ #{temperature}°C / #{fahrenheit}°F     │
      │ Humidity: #{humidity}%        │
      │ #{timestamp.strftime("%Y-%m-%d %H:%M")} │
      └─────────────────────┘
    TEXT
  end

  def fahrenheit
    (temperature * 9.0 / 5.0 + 32.0).round(1)
  end
end

# ---------- Main ----------

if __FILE__ == $PROGRAM_NAME
  forecast = Forecast.new

  # Simulate readings
  readings = [
    WeatherReading.new(temperature: 28.5, humidity: 65, pressure: 1013, location: "São Paulo"),
    WeatherReading.new(temperature: 32.1, humidity: 70, pressure: 1011, location: "Rio de Janeiro"),
    WeatherReading.new(temperature: 26.3, humidity: 60, pressure: 1015, location: "Belo Horizonte"),
  ]

  readings.each { |r| forecast.add(r) }

  puts "=== Weather Summary ==="
  puts JSON.pretty_generate(forecast.summary)

  puts "\n=== Detailed Readings ==="
  forecast.readings.each do |reading|
    puts ReadingDecorator.new(reading).formatted
  end

  puts "\n=== Fahrenheit Check ==="
  puts "30°C = #{30.celsius_to_fahrenheit}°F"
end

require "net/http"
require "json"

class VpnCheckService
  API_URL = "https://vpnapi.io/api/".freeze
  API_KEY = ENV.fetch("VPN_API_KEY") { raise "VPN_API_KEY is not set" }

  def initialize(ip)
    @ip = ip
  end

  def call
    cached = REDIS.get(cache_key)
    return JSON.parse(cached) if cached

    response = fetch_from_api

    REDIS.setex(cache_key, 24.hours.to_i, response.to_json)

    response
  rescue StandardError => e
    Rails.logger.warn("VpnCheckService failed for #{@ip}: #{e.message}")
    fallback
  end

  private

  def cache_key
    "vpn:#{@ip}"
  end

  def fetch_from_api
    uri = URI("#{API_URL}#{@ip}?key=#{API_KEY}")
    res = Net::HTTP.get_response(uri)

    JSON.parse(res.body)
  end

  def fallback
    { "security" => { "vpn" => false, "tor" => false } }
  end
end

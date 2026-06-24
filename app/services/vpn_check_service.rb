require "net/http"
require "json"

class VpnCheckService
  API_URL = "https://vpnapi.io/api/".freeze

  def initialize(ip)
    @ip = ip
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      fetch_from_api
    end
  rescue StandardError => e
    Rails.logger.warn("VpnCheckService failed for #{@ip}: #{e.message}")
    fallback
  end

  private

  def cache_key
    "vpn:#{@ip}"
  end

  def fetch_from_api
    uri = URI("#{API_URL}#{@ip}")
    uri.query = URI.encode_www_form(key: api_key)

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 2, read_timeout: 2) do |http|
      http.get(uri.request_uri)
    end

    raise "Vpn API request failed: #{res.code}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end

  def api_key
    ENV.fetch("VPN_API_KEY") { raise "VPN_API_KEY is not set" }
  end

  def fallback
    { "security" => { "vpn" => false, "tor" => false, "proxy" => false } }
  end
end

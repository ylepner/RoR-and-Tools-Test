class CountryWhitelistStore
  def allowed?(country)
    code = country.to_s.strip.upcase
    return false if code.empty?

    REDIS.sismember("country_whitelist", code)
  end
end

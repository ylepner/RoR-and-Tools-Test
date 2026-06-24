class RedisPool
  def initialize(size:, timeout:, url:)
    @pool = ConnectionPool.new(size: size, timeout: timeout) do
      Redis.new(url: url)
    end
  end

  def method_missing(method, *args, &block)
    @pool.with { |conn| conn.public_send(method, *args, &block) }
  end

  def respond_to_missing?(method, include_private = false)
    Redis.instance_methods.include?(method) || super
  end
end

redis_config = Rails.application.config_for(:redis)

REDIS = RedisPool.new(
  size: redis_config[:pool_size].to_i,
  timeout: redis_config[:pool_timeout].to_i,
  url: redis_config[:url]
)

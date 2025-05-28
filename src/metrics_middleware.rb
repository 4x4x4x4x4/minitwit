require 'prometheus/client'

class MetricsMiddleware
  def initialize(app)
    @app = app
    registry = Prometheus::Client.registry

    @counter = registry.counter(
      :minitwit_http_responses_total,
      docstring: 'Total HTTP responses served',
      labels: [:status, :method, :path]
    )

    @duration = registry.histogram(
      :minitwit_request_duration_milliseconds,
      docstring: 'Request duration in ms',
      labels: [:method, :path]
    )
  end

  def call(env)
    req = Rack::Request.new(env)

    # Don't collect metrics for /metrics path to avoid infinite loop
    return @app.call(env) if req.path.start_with?("/metrics")

    start = Time.now
    status, headers, response = @app.call(env)
    elapsed = (Time.now - start) * 1000.0

    path = req.path_info
    method = req.request_method

    @counter.increment(labels: { status: status.to_s, method: method, path: path })
    @duration.observe(elapsed, labels: { method: method, path: path })

    [status, headers, response]
  end
end

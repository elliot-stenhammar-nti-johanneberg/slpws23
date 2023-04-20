class RequestLimiter
    def initialize(app, options = {})
        @app = app
        @cooldown = options[:cooldown] || 0.1
        @requests = {}
    end

    def call(env)
        ip = env['REMOTE_ADDR']

        if @requests[ip] && Time.now - @requests[ip] < @cooldown
            [429, {}, ['Too Many Requests']]
        else
            @requests[ip] = Time.now
            @app.call(env)
        end
      end
end
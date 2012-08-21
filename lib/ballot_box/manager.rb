# encoding: utf-8
module BallotBox
  class Manager
    extend BallotBox::Callbacks
    
    attr_accessor :config
    
    # Initialize the middleware. If a block is given, a BallotBox::Config is yielded so you can properly
    # configure the BallotBox::Manager.
    def initialize(app, options={})
      options.symbolize_keys!

      @app, @config = app, BallotBox::Config.new(options)
      yield @config if block_given?
      self
    end
    
    def call(env) # :nodoc:
      if voting_path?(env['PATH_INFO']) && env["REQUEST_METHOD"] == "POST"
        create(env)
      else
        @app.call(env)
      end
    end
    
    # :api: private
    def _run_callbacks(*args) #:nodoc:
      self.class._run_callbacks(*args)
    end
    
    protected
      
      def create(env, body = '', status = 500)
        request = Rack::Request.new(env)
        vote = BallotBox::Vote.new(:request => request)
        vote.voteable_type = @config.routes[ request.path_info ]
        
        _run_callbacks(:before_vote, env, vote)
        
        body, status = vote.call
        
        _run_callbacks(:after_vote, env, vote)
        
        [status, {'Content-Type' => 'application/json', 'Content-Length' => body.size.to_s}, [body]]
      end
      
      def voting_path?(request_path)
        return false if @config.routes.nil?

        @config.routes.keys.any? do |route|
          route == request_path
        end
      end
  end
end

require "http/server"
require "radix"

class HTTP::Router < HTTP::Server
  property trees = {} of String => Radix::Tree(Proc(HTTP::Server::Context,Nil))#, server : HTTP::Server 

  def self.new(handler : HTTP::Handler) : self
    new([handler] of HTTP::Handler)
  end

  def initialize(handlers : Array(HTTP::Handler))
    @processor = RequestProcessor.new(HTTP::Server.build_middleware(handlers,->call(HTTP::Server::Context)))
  end

  def initialize
    @processor = RequestProcessor.new(->call(HTTP::Server::Context))
  end

  def call(context)
    method = context.request.method
    if @trees.has_key? method
      result = @trees[method].find context.request.path
      if result.found?
        result.payload.call(context)
      end
    end
  end


  macro generate_add_method(arr)
    {% for name,i in arr %}
      def {{name.downcase.id}}(path : String, &block : HTTP::Server::Context ->)
        add path, {{name}}, block
      end
    {% end %}
  end
  generate_add_method(["GET","POST", "PUT","DELETE","HEAD","TRACE","CONNECT","OPTIONS","PATCH"])

  def add(path : String, method : String, &block : HTTP::Server::Context ->)
    add path, method, block
  end

  def add(path : String, methods : Array(String), &block : HTTP::Server::Context ->)
    methods.each do |method|
      add path, method, block
    end
  end

  def add(path : String, method : String, listener : Proc(HTTP::Server::Context, Nil))
    if !@trees.has_key? method
      @trees[method] = Radix::Tree(Proc(HTTP::Server::Context,Nil)).new
    end
    @trees[method].add path, listener
  end
  
  def add(path : String, methods : Array(String), listener : Proc(HTTP::Server::Context, Nil))
    methods.each do |method|
      add path, method, listener
    end
  end

  # Returns a proc, which can be called, to block the server, until it is closed
  def listen_non_blocking
    raise "Can't re-start closed server" if closed?
    raise "Can't start server with no sockets to listen to, use HTTP::Server#bind first" if @sockets.empty?
    raise "Can't start running server" if listening?

    @listening = true
    done = Channel(Nil).new

    @sockets.each do |socket|
      spawn do
        until closed?
          io = begin
            socket.accept?
          rescue e
            handle_exception(e)
            nil
          end

          if io
            # a non nillable version of the closured io
            _io = io
            spawn handle_client(_io)
          end
        end
      ensure
        done.send nil
      end
    end

    Proc(Nil).new {
      @sockets.size.times { done.receive }
    }
  end

  def listen(blocking = true)
    if blocking
      listen
      Proc(Nil).new{}
    else
      listen_non_blocking
    end
  end


end

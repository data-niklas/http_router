# http_router

A simple and fast http server router, similar to NodeJS express

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     http_router:
       github: data-niklas/http_router
   ```

2. Run `shards install`

## Usage

```crystal
require "http_router"

router = HTTP::Router.new
router.get "/test/:test/123"  { |context|
    puts "Called",context.request.path
    context.response.print "Hello there"
}

router.post "/test"  { |context|
    puts "Called",context.request.path
    context.response.print "Called /test with the post method"
}

router.bind_tcp 8080
router.listen
```

Other methods like put, patch, head, ... are available.<br>
The HTTP::Router extends the HTTP::Server, so the default server code should work.<br>
"/test/:sth/123" will match any url, which contains something between /test/ and 123,<br>
so e.g.: "/test/testing/123<br>
the router can also listen in a non blocking kind of way. The above code would be changed in the following kind of way:<br>

```
proc = router.listen_non_blocking
# do something
spawn do
  # Block the fiber until the server is closed
  proc.call
  puts "Server closed"
end
sleep 10
router.close
sleep 1
puts "Will exit!"
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/data-niklas/http_router/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Niklas Loeser](https://github.com/data-niklas) - creator and maintainer

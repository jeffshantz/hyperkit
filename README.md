# Hyperkit

Hyperkit is a flat API wrapper for LXD, the next-generation hypervisor.
It is shamelessly based on the design of Octokit, the popular wrapper for
the GitHub API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hyperkit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hyperkit

## Usage

```
require 'hyperkit'
require 'pry'

# By default, Hyperkit connects to the LXD API at https://localhost:8443
client = Hyperkit.client

# If using the default self-signed LXD certificate, turn off SSL verification
client.connection_options[:ssl][:verify] = false

# List all profiles
profiles = client.profiles

# Get a specific profile
profile = client.profile('docker')

# Create a profile for containers in which 'eth0' inside the container will be 
# plugged into the host's 'br-ext' bridge:
client.create_profile('new-profile', {
  devices: {
    eth0: {
      nictype: 'bridged',
      parent: 'br-ext',
      type: 'nic'
    }
  }
})
```

If connecting to a different LXD host:

```
client = Hyperkit::Client.new(api_endpoint: 'https://images.linuxcontainers.org:8443')
```

Alternatively, you can configure settings for all Hyperkit clients:

```
Hyperkit.configure do |c|
  c.api_endpoint = 'https://images.linuxcontainers.org:8443'
end

client = Hyperkit.client
```

## Authentication

The LXD API uses client-side certificates to authenticate clients.
By default, Hyperkit uses the following files:

* Certificate: `ENV['HOME']/.config/lxc/client.crt`
* Private key: `ENV['HOME']/.config/lxc/client.key`

To specify alternate files:

```
client = Hyperkit::Client.new(client_cert: '/path/to/crt/file', client_key: '/path/to/key/file')
```

or, to configure all new instances of Hyperkit:

```
Hyperkit.configure do |c|
  c.client_cert = '/path/to/crt/file'
  c.client_key = '/path/to/key/file'
end
```

## API coverage

Hyperkit endeavours to support the entirety of [version 1.0 of the LXD API](https://github.com/lxc/lxd/blob/master/specs/rest-api.md).
Currently, we support:

* /1.0/profiles

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will create
a git tag for the version, push git commits and tags, and push the `.gem`
file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/hyperkit. This project is intended to be
a safe, welcoming space for collaboration, and contributors are expected
to adhere to the [Contributor Covenant](http://contributor-covenant.org)
code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).  Its design is based on
Octokit, also licensed under the MIT license.  See the file `LICENSE`
for more information.


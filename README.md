# Hyperkit

Hyperkit is a flat API wrapper for LXD, the next-generation hypervisor.  It is
shamelessly based on the design of Octokit, the popular wrapper for the GitHub
API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hyperkit'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install hyperkit
```

## Usage examples

```ruby
require 'hyperkit'

lxd = Hyperkit::Client.new(api_endpoint: "https://lxd.example.com", verify_ssl: false)

# Create a new container and start it
lxd.create_container("test-container", alias: "ubuntu/trusty/amd64")
lxd.start_container("test-container")

# Execute a command in a container
lxd.execute_command("test-container", "bash -c 'echo hello > /tmp/test.txt'")

# Create an image from a container and assign an alias to it
response = lxd.create_image_from_container("test-container")
lxd.create_image_alias(response.metadata.fingerprint, "ubuntu/custom")

# Take a snapshot of a container (note that CRIU must be installed to snapshot
# a running container)
lxd.create_snapshot("test-container", "test-snapshot")

# Migrate a container (or a snapshot) from one server to another
# Note that CRIU must be installed on both LXD servers to migrate a running
# container.
lxd2 = Hyperkit::Client.new(api_endpoint: "https://lxd2.example.com")
source = lxd2.init_migration("remote-container")
lxd.migrate_container(source, "migrated-container")
```

Each method in the API documentation has at least one example of its usage.   Please see the documentation for the following modules:

* [Certificates]()
* [Containers]()
* [Images]()
* [Networks]()
* [Operations]()
* [Profiles]()

## Requirements

Hyperkit supports **LXD 2.0.0 and above**, and **Ruby 2.0 and above**.

To get started, you'll need to first enable the HTTPS API on your LXD server:

```
$ lxc config set core.https_address 127.0.0.1
```

To listen on all interfaces, replace `127.0.0.1` with `0.0.0.0`.

### Making requests

Being based on Octokit, [API methods][] are available as module methods
(consuming module-level configuration) or as client instance methods.

```ruby
Hyperkit.configure do |c|
  c.api_endpoint = 'https://lxd.example.com:8443'
  c.verify_ssl = false
end

# Create an Ubuntu 14.04 container
Hyperkit.create_container("test-container", alias: "ubuntu/trusty/amd64")
```
or

```ruby
client = Octokit::Client.new(api_endpoint: 'https://lxd.example.com:8443', verify_ssl: false)

# Create an Ubuntu 14.04 container
client.create_container("test-container", alias: "ubuntu/trusty/amd64")
```

[API methods]: http://TODO

## Authentication

The LXD API uses client-side certificates to authenticate clients.  By
default, Hyperkit uses the following files:

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

If you're running Hyperkit on your LXD host, the `lxc` tool should have
already generated your certificate and private key for you, and placed them in
`~/.config/lxc`.

If you are running Hyperkit on a different host, you'll need to generate a
certificate and private key.  To do this, install OpenSSL and issue the
following commands:

```
mkdir -p ~/.config/lxc
openssl req -x509 -newkey rsa:2048 -keyout ~/.config/lxc/client.key.secure -out ~/.config/lxc/client.crt -days 3650
openssl rsa -in ~/.config/lxc/client.key.secure -out ~/.config/lxc/client.key
```

You will then need to tell LXD to trust your certificate.  You can do this in
two ways:

### Option 1: Trusting your certificate using a trust password

If you have configured your LXD server with a trust password, you can use
Hyperkit to get your certificate trusted:

```ruby
require 'hyperkit'

Hyperkit.api_endpoint = 'https://lxd.example.com:8443'
Hyperkit.verify_ssl = false   # Needed if you're using a self-signed certificate on the server

Hyperkit.create_certificate(File.read("/path/to/your/client.crt"), password: "server-trust-password")
```

### Option 2: Trusting your certificate using the `lxc` tool

Alternatively, you can simply copy your certificate file to the LXD server and
use the `lxc` tool to trust it:

```
lxd-server$ lxc config trust add my-new-cert.crt
```

## API coverage

Hyperkit supports the entirety of [version 1.0 of the LXD
API](https://github.com/lxc/lxd/blob/master/specs/rest-api.md), but does not
support any of the Websocket API calls (e.g. `/1.0/events`).

## Asynchronous Operations

A good deal of the LXD API calls are asynchronous: you issue the call, and you
receive an operation ID.  You must then wait on the operation to complete.
Each asynchronous method is marked as such in the Hyperkit documentation.

**By default, Hyperkit provides auto-synchronization**.  When you initiate an
asynchronous operation, Hyperkit will automatically wait for the operation to
complete before returning.

For example,

```ruby
# By default, this will block until the container is created
Hyperkit.create_container("test-container", alias: "ubuntu/trusty/amd64")
```

If you wish to override this functionality, there are two ways to do this.
First, you can pass `sync: false` to any of the asynchronous methods:

```ruby
# Initiates the operation and immediately returns an operation ID
op = Hyperkit.create_container("test-container", alias: "ubuntu/trusty/amd64", sync: false)

# Blocks until the operation is complete
Hyperkit.wait_for_operation(op.id)
```

Alternatively, you can disable auto-synchronization at the module or class
level:

```ruby
Hyperkit.auto_sync = false

# or

client = Hyperkit::Client.new(auto_sync: false)
```

Any asynchronous calls you issue after setting `auto_sync` to `false` will
immediately return an operation ID instead of blocking.  To ensure that an
operation is complete, you will need to call `wait_for_operation`:

```ruby
Hyperkit.auto_sync = false

op = Hyperkit.create_container("test-container", alias: "ubuntu/trusty/amd64")
Hyperkit.wait_for_operation(op.id)
```

Note that, after an operation completes, LXD keeps it around for only 5
seconds, so if you wait too long to call `wait_for_operation`, you'll get an
exception when you eventually do call it.

Most users will likely want to keep `auto_sync` enabled for convenience.


## Configuration and defaults

Hyperkit allows you to configure a new `Hyperkit::Client` instance by passing
options to its constructor.

As in Octokit, you also have the option of setting configuration at the module
level.  If you need to create a number of client instances which will share
certain options, this ability will be useful.

When you change options at the module level, only new `Hyperkit::Client`
instances will be affected -- any existing instances that you have created
will retain their existing configuration.

### Configuring module defaults

Every writable attribute in {Hyperkit::Configurable} can be set one at a time:

```ruby
Hyperkit.api_endpoint = 'https://lxd.example.com:8443'
Hyperkit.verify_ssl   = false
Hyperkit.client_cert  = '/home/user/client.crt'
Hyperkit.client_key   = '/home/user/client.key'
```

or in batch:

```ruby
Hyperkit.configure do |c|
  c.api_endpoint = 'https://lxd.example.com:8443'
  c.verify_ssl   = false
  c.client_cert  = '/home/user/client.crt'
  c.client_key   = '/home/user/client.key'
end
```

### Using ENV variables

Default configuration values are specified in {Hyperkit::Default}. Many
attributes will look for a default value from the `ENV` before returning
Hyperkit's default.

```ruby
# Given $HYPERKIT_API_ENDPOINT is "https://lxd.example.com:8443"
Hyperkit.api_endpoint

# => "https://lxd.example.com:8443"
```


## Supported Ruby Versions

This library aims to support and is [tested against][travis] the following
Ruby implementations:

* Ruby 2.0
* Ruby 2.1
* Ruby 2.2

If something doesn't work on one of these interpreters, it's a bug.  This
library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0][semver]. Violations
of this scheme should be reported as bugs. Specifically, if a minor or patch
version is released that breaks backward compatibility, that version should be
immediately yanked and/or a new version should be immediately released that
restores compatibility. Breaking changes to the public API will only be
introduced with new major versions. As a result of this policy, you can (and
should) specify a dependency on this gem using the [Pessimistic Version
Constraint][pvc] with two digits of precision. For example:

```ruby
spec.add_dependency 'hyperkit', '~> 1.0'
```
[semver]: http://semver.org/
[pvc]: http://docs.rubygems.org/read/chapter/16#page74

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/jeffshantz/hyperkit. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).  Its design is based on Octokit,
also licensed under the MIT license.  See the file `LICENSE.txt` for more
information.


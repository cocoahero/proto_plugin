# frozen_string_literal: true

require_relative "lib/proto_plugin/version"

Gem::Specification.new do |spec|
  spec.name = "proto_plugin"
  spec.version = ProtoPlugin::VERSION
  spec.authors = ["Jonathan Baker"]
  spec.email = ["jonathan@jmb.dev"]
  spec.license = "MIT"

  spec.required_ruby_version = "~> 3.1"

  spec.summary = "Easily build protobuf compiler plugins in Ruby."

  spec.homepage = "https://github.com/cocoahero/proto_plugin"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "documentation_uri" => "https://cocoahero.github.io/proto_plugin",
    "allowed_push_host" => "https://rubygems.org",
    "funding_uri" => "https://github.com/sponsors/cocoahero",
  }

  spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md"]

  spec.bindir = "exe"
  spec.executables = ["protoc-gen-proto-plugin-demo"]

  spec.require_paths = ["lib"]

  spec.add_dependency("google-protobuf", "~> 4.28")
end

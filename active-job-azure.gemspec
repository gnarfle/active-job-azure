# frozen_string_literal: true

require_relative "lib/active_job_azure/version"

Gem::Specification.new do |spec|
  spec.name          = "active_job_azure"
  spec.version       = ActiveJobAzure::VERSION
  spec.authors       = ["Chad Cunningham"]
  spec.email         = ["chadcf@gmail.com"]

  spec.summary       = "Adds ActiveJob support for azure queue storage"
  spec.description   = "Adds ActiveJob support for azure queue storage"
  spec.homepage      = "https://github.com/chadcf/active-job-azure"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.require_paths = ["lib"]

  spec.executables = %w[azure-queue-worker]

  spec.add_dependency "azure-storage-queue", "~> 2.0"
  spec.add_dependency "activejob", "> 5.2"
  spec.add_dependency "concurrent-ruby", "~> 1.1.0"
  spec.add_dependency "slop", "~> 4.8.0"
  spec.add_dependency "typhoeus", "> 1.4bundl"

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'dotenv'
  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end

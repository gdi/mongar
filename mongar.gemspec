# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "mongar"
  s.version = "0.0.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Philippe Green"]
  s.date = "2015-09-11"
  s.description = "Replicates data from ActiveRecord (or other Ruby data mapping class) to MongoDB"
  s.email = "phil@greenviewdata.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/mongar.rb",
    "lib/mongar/column.rb",
    "lib/mongar/mongo.rb",
    "lib/mongar/mongo/collection.rb",
    "lib/mongar/replica.rb",
    "mongar.gemspec",
    "spec/fixtures/configure.rb",
    "spec/fixtures/full_configure.rb",
    "spec/fixtures/sources.rb",
    "spec/integration_spec.rb",
    "spec/mongar/column_spec.rb",
    "spec/mongar/mongo/collection_spec.rb",
    "spec/mongar/mongo_spec.rb",
    "spec/mongar/replica_spec.rb",
    "spec/mongar_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/gdi/mongar"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.29"
  s.summary = "Replicates data from ActiveRecord (or other Ruby data mapping class) to MongoDB"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<linguistics>, [">= 0"])
      s.add_runtime_dependency(%q<mongo>, ["= 1.12.3"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_development_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<linguistics>, [">= 0"])
      s.add_dependency(%q<mongo>, ["= 1.12.3"])
      s.add_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<linguistics>, [">= 0"])
    s.add_dependency(%q<mongo>, ["= 1.12.3"])
    s.add_dependency(%q<rspec>, ["~> 2.3.0"])
    s.add_dependency(%q<yard>, ["~> 0.6.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end


#!/usr/bin/env ruby


require 'juici'
::Juici::Database.initialize!

builds = ARGV
if builds.empty?
  puts `Kills all pending builds.
Usage:
  ./scripts/kick_builds.rb "99designs/finance-dashboard" "99designs/other_build_to_kick"
  `
  exit(1)
end

builds.each do |build|
  ::Juici::Build.where(
    parent: build,
    status: ::Juici::Build::WAIT
  ).each &:failure!
end

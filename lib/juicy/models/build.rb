# status enum
#   :waiting
#   :started
#   :failed
#   :success
#
#   ???
#   :profit!
#
module Juicy
  class Build
    # A wrapper around the build process

    include Mongoid::Document
    include ::Juicy.url_helpers("builds")
    include BuildLogic
    # TODO Builds should probably be children of projects in the URL?

    field :parent, type: String
    field :command, type: String
    field :environment, type: Hash
    field :create_time, type: Time, :default => Proc.new { Time.now }
    field :start_time, type: Time, :default => nil
    field :end_time, type: Time, :default => nil
    field :status, type: Symbol, :default => :waiting
    field :priority, type: Fixnum, :default => 1
    field :pid, type: Fixnum
    field :buffer, type: String
    field :warnings, type: Array, :default => []

    def set_status(value)
      self[:status] = value
      save!
    end

    def start!
      self[:start_time] = Time.now
      set_status :started
    end

    def success!
      finish
      set_status :success
    end

    def failure!
      finish
      set_status :failed
    end

    def finish
      self[:end_time] = Time.now
      self[:output] = get_output
      $build_queue.purge(:pid, self)
    end

    def build!
      if (pid = spawn_build)
        start!
        Juicy.dbgp "#{pid} away!"
        self[:pid] = pid
        self[:buffer] = @buffer.path
        save!
      else
        failure!
      end
      return pid
    end

    def worktree
      File.join(Config.workspace, parent)
    end

    # View helpers
    def heading_color
      case status
      when :waiting
        "build-heading-pending"
      when :failed
        "build-heading-failed"
      when :success
        "build-heading-success"
      when :started
        "build-heading-started"
      end
    end

    def get_output
      return "" unless self[:buffer]
      File.open(self[:buffer], 'r') do |f|
        f.rewind
        f.read
      end
    end

    def warn!(msg)
      warnings << msg
      save!
    end

  end
end

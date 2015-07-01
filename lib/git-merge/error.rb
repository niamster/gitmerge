module GitMerge
  class InvalidCommit < StandardError
    def initialize(commit)
      super "Invalid commit '#{commit}'"
    end
  end

  class NotLocalHead < StandardError
    def initialize(head)
      super "Head '#{head}' is not local"
    end
  end

  class MergeConflict < StandardError
  end

  class DirtyIndex < StandardError
  end
end

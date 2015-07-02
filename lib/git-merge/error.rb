module GitMerge
  class GitMergeError < StandardError
  end

  class InvalidCommit < GitMergeError
    def initialize(commit)
      super "Invalid commit '#{commit}'"
    end
  end

  class InvalidHead < GitMergeError
    def initialize(head)
      super "Invalid head '#{head}'"
    end
  end

  class NotLocalHead < GitMergeError
    def initialize(head)
      super "Head '#{head}' is not local"
    end
  end

  class MergeConflict < GitMergeError
  end

  class MergeInProgress < GitMergeError
  end

  class DirtyIndex < GitMergeError
  end
end

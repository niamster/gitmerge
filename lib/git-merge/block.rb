module GitMerge
  class Block
    BLOCKED = '.git-blocked'
    MAX_LEN = 80
    SEP = "\n"

    def initialize(repo, branch: nil)
      @repo = repo
      @head = @repo.get_head branch
    end

    def get_blocked
      index = @repo.get_index @head
      obj = index[BLOCKED]
      return [] unless obj
      obj = @repo.repo.lookup obj[:oid]
      obj.content.split SEP
    end

    def block(hashes)
      commits = lookup_commits hashes
      block_commits commits
    end

    private

    def write_blocked(blocked)
      blocked = blocked.reject { |e| e.length == 0 }
      blocked += ['']
      blocked = blocked.join SEP
      @repo.repo.write(blocked, :blob)
    end

    def commit_blocked(blocked, message)
      oid = write_blocked blocked
      index = @repo.get_index @head
      index.add path: BLOCKED, oid: oid, mode: 0100644

      @repo.commit @head, index, message
    end

    def mk_message(blocked)
      blocked.each_with_object(['Blocking commits: ']) do |commit, message|
        desc = commit.message.chomp
        desc = desc[0..MAX_LEN] + ' ...' if desc.length > MAX_LEN
        message << "#{commit.oid} -- #{desc}"
      end.join SEP
    end

    def filter_blocked(commits, blocked)
      commits.each_with_object([]) do |commit, unblocked|
        oid = commit.oid
        next if blocked.include? oid
        Logger.debug "Blocking #{oid} in #{@head.name}"
        unblocked << commit
      end
    end

    def block_commits(commits)
      blocked = get_blocked
      unblocked = filter_blocked commits, blocked
      if unblocked.length == 0
        Logger.info 'All commits already blocked'
        return
      end
      message = mk_message unblocked
      blocked += unblocked.map(&:oid)
      commit_blocked blocked, message
    end

    def lookup_commits(hashes)
      hashes.each_with_object([]) do |hash, commits|
        commit = @repo.repo.lookup hash
        fail InvalidCommit, hash unless commit
        commits << commit
      end
    end
  end
end

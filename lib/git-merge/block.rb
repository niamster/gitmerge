module GitMerge
  class Block
    BLOCKED = '.git-blocked'
    MAX_LEN = 80
    SEP = "\n"

    def initialize(repo)
      @repo = repo
    end

    def get_blocked(head)
      index = @repo.get_index head
      obj = index[BLOCKED]
      return [] unless obj
      obj = @repo.repo.lookup obj[:oid]
      obj.content.split SEP
    end

    def write_blocked(blocked)
      blocked = blocked.reject { |e| e.length == 0 }
      blocked += ['']
      blocked = blocked.join SEP
      @repo.repo.write(blocked, :blob)
    end

    def commit_blocked(head, blocked, message)
      oid = write_blocked blocked
      index = @repo.get_index head
      index.add(path: BLOCKED, oid: oid, mode: 0100644)

      options = {}
      options[:tree] = index.write_tree(@repo.repo)
      options[:author] = @repo.author
      options[:committer] = @repo.author
      options[:message] = message
      options[:parents] = [head.target]
      options[:update_ref] = head.name

      Rugged::Commit.create(@repo.repo, options)
    end

    def mk_message(blocked)
      blocked.each_with_object(['Blocking commits: ']) do |commit, message|
        desc = commit.message.chomp
        desc = desc[0..MAX_LEN] + ' ...' if desc.length > MAX_LEN
        message << "#{commit.oid} -- #{desc}"
      end.join SEP
    end

    def filter_blocked(commits, blocked, head)
      commits.each_with_object([]) do |commit, unblocked|
        oid = commit.oid
        next if blocked.include? oid
        Logger.debug "Blocking #{oid} in #{head.name}"
        unblocked << commit
      end
    end

    def block_commits(commits, head)
      blocked = get_blocked head
      unblocked = filter_blocked commits, blocked, head
      if unblocked.length == 0
        Logger.info 'All commits already blocked'
        return
      end
      message = mk_message unblocked
      blocked += unblocked.map(&:oid)
      commit_blocked head, blocked, message
    end

    def lookup_commits(hashes)
      hashes.each_with_object([]) do |hash, commits|
        commit = @repo.repo.lookup hash
        fail InvalidCommit, hash unless commit
        commits << commit
      end
    end

    def block(hashes: [], head: nil)
      return unless hashes
      head = @repo.get_head head
      commits = lookup_commits hashes
      block_commits commits, head
    end
  end
end

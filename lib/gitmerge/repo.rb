module GitMerge
  class Repo
    attr_accessor :repo
    attr_accessor :path

    def initialize(path, user=nil)
      @path = path
      @user = user
      @repo = Rugged::Repository.new path
    end

    def author
      return nil unless @user
      {email: @user[:email], name: @user[:name], time: Time.now}
    end

    def get_head(head, need_local=true)
      return @repo.head unless head
      unless @repo.branches.each_name(:local).include? head
        fail NotLocalHead, head if need_local
      end
      [head,
       "refs/heads/#{head}",
       "refs/remotes/#{head}"].each do |name|
        ref = @repo.references[name] rescue nil
        next unless ref
        Logger.debug "#{head} resolved as #{name}" unless head == name
        return ref
      end
      fail InvalidHead, head
    end

    def checkout_index(index, head)
      @repo.checkout_index index, strategy: :force
      @repo.head = head.name
    end

    def rev(commit)
      @repo.rev_parse commit
    end

    def get_index(head)
      index = @repo.index
      index.read_tree head.target.tree
      index.reload
      index
    end

    def clean?
      @repo.status do |file, status|
        next if status.include? :worktree_new
        return false
      end
      true
    end

    def commit(head, index, message, parents=[])
      options = {}
      options[:tree] = index.write_tree @repo
      options[:author] = author
      options[:committer] = author
      options[:message] = message
      options[:parents] = [head.target] + parents
      options[:update_ref] = head.name

      do_commit head, options
    end

    def lookup_commits(hashes)
      hashes.each_with_object([]) do |hash, commits|
        commit = @repo.lookup hash rescue nil
        fail InvalidCommit, hash unless commit
        commits << commit
      end
    end

    def commit_list(from, to)
      walker = Rugged::Walker.new(@repo)
      walker.sorting Rugged::SORT_TOPO | Rugged::SORT_REVERSE
      walker.push_range "#{to.target.oid}..#{from.target.oid}"
      exclude = to.log.map { |e| e[:id_new] }
      diff = []
      walker.each_oid do |oid|
        next if exclude.include? oid
        diff << oid
      end
      diff
    end

    def merge_info(head, commit)
      their = rev commit
      base = @repo.merge_base head.target, their
      base = rev base
      [base, their]
    end

    private

    def do_commit(head, options)
      checkout = false
      if @repo.head.name == head.name
        fail DirtyIndex unless clean?
        checkout = true
      end

      Rugged::Commit.create @repo, options

      return unless checkout
      Logger.warn 'Forcing checkout after commit'
      @repo.checkout_head strategy: :force
    end
  end
end

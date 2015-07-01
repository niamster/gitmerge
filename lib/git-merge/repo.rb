module GitMerge
  class Repo
    attr_accessor :repo

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
    end

    def rev(commit)
      @repo.rev_parse commit
    end

    def get_index(head)
      index = @repo.index
      index.read_tree head.target.tree
      index
    end

    def clean
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

    private

    def do_commit(head, options)
      checkout = false
      if @repo.head.target.oid == head.target.oid
        fail DirtyIndex unless clean
        checkout = true
      end

      Rugged::Commit.create @repo, options

      if checkout
        Logger.warn 'Forcing checkout after commit'
        @repo.checkout_head strategy: :force
      end
    end
  end
end

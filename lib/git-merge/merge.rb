module GitMerge
  class Merge
    MERGE_MARKS = {
      head: 'MERGE_HEAD',
      msg: 'MERGE_MSG',
    }
    SEP = "\n"

    def initialize(repo, branch: nil)
      @repo = repo
      @branch = branch
      @head = @repo.get_head @branch
    end

    def merge!(from)
      @from = @repo.get_head from, false
      commits = @repo.commit_list @from, @head
      return unless commits
      block = GitMerge::Block.new @repo, branch: @branch
      blocked = block.fetch_blocked
      merge_commits commits, blocked
    ensure
      @from = nil
    end

    private

    def merge_commits(commits, blocked)
      pcommit, pblock = nil, nil
      commits.each do |commit|
        if blocked.include? commit
          merge_normal pcommit
          pblock = commit
          pcommit = nil
          next
        end
        merge_ours pblock
        pblock = nil
        pcommit = commit
      end
      merge_ours pblock
      merge_normal pcommit
    end

    def write_marks(marks, meta)
      marks.each do |mark, path|
        File.open(path, 'w') do |f|
          f << meta[mark]
          f << SEP
        end
      end
    rescue => e
      Logger.fatal e
      marks.each do |mark, path|
        File.unlink path rescue nil
      end
    end

    def mark_merge(commit, index)
      marks = MERGE_MARKS.each_with_object({}) do |(mark, file), storage|
        storage[mark] = File.join @repo.path, '.git', file
        fail MergeInProgress if File.exist? storage[mark]
      end
      conflicts = index.conflicts.each_with_object(Set.new) do |conflict, storage|
        storage << conflict[:ancestor][:path]
      end.to_a
      meta = {
        msg: msg(commit, conflicts),
        head: commit,
      }
      write_marks marks, meta
    end

    def resolve_conflict(commit, index)
      Logger.warn "Merge conflict when mergin #{commit} into #{@head.name}"
      unless @repo.clean?
        Logger.error "Can't resolve merge conflict in a dirty repository"
        exit 1
      end
      @repo.checkout_index index, @head
      mark_merge commit, index
      Logger.info "Working directory #{@repo.path} was updated for manual merge conflict resolution"
      Logger.info "please step into, resolve conflict, stage and commit" \
                  "resolved entries (via `git add` and `git commit`)."
      Logger.info "Afterwards you might need to run git-merge again to finish the merge."
      exit
    end

    def msg(commit, conflicts=nil)
      name = commit
      name = @from.name if @from.target.oid == commit
      msg = ["Merge #{name} into #{@head.name}"]
      if conflicts
        msg << '# Conflicts:'
        conflicts.each do |conflict|
          msg << "#       #{conflict}"
        end
      end
      msg.join SEP
    end

    def do_merge(commit, favor=:normal)
      base, their = @repo.merge_info @head, commit
      our = @head.target.tree
      index = our.merge their.tree, base.tree, favor: favor
      resolve_conflict commit, index if index.conflicts?
      @repo.commit @head, index, msg(commit), [their]
      @head = @repo.get_head @branch
    end

    def merge_ours(commit)
      return unless commit
      Logger.info "Merging #{commit} as ours"
      do_merge commit, :ours
    end

    def merge_normal(commit)
      return unless commit
      Logger.info "Merging #{commit}"
      do_merge commit
    end
  end
end

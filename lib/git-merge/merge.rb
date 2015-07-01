module GitMerge
  class Merge
    def initialize(repo, branch: nil)
      @repo = repo
      @branch = branch
      @head = @repo.get_head @branch
    end

    def merge(from)
      from = @repo.get_head from, false
      commits = commit_list from
      return unless commits
      block = GitMerge::Block.new @repo, branch: @branch
      blocked = block.get_blocked
      merge_commits commits, blocked
    end

    private

    def commit_list(from)
      walker = Rugged::Walker.new(@repo.repo)
      walker.sorting Rugged::SORT_TOPO | Rugged::SORT_REVERSE
      walker.push_range "#{@head.target.oid}..#{from.target.oid}"
      walker.each_oid.to_a
    end

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

    def merge_info(commit)
      their = @repo.rev commit
      base = @repo.repo.merge_base @head.target, their
      base = @repo.rev base
      [base, their]
    end

    def do_merge(commit, favor=:normal)
      base, their = merge_info commit
      our = @head.target.tree
      index = our.merge their.tree, base.tree, favor: favor
      fail MergeConflict if index.conflicts?
      @repo.commit @head, index, "Merging #{commit} into #{@head.name}", [their]
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

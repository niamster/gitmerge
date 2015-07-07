module GitMerge::Test
  class Repo
    attr_accessor :sandbox
    attr_accessor :tree

    def initialize
      @sandbox = Dir.mktmpdir("gitmerge")
      ObjectSpace.define_finalizer(self, proc { FileUtils.rm_rf @sandbox })
      @repo = Rugged::Repository.init_at @sandbox
      @tree = {'master' => []}
      __init
    end

    def create_branch(name)
      @repo.create_branch name
      @tree[name] = []
    end

    def write_file(branch, path, data, msg)
      oid = @repo.write data, :blob
      index, ref = resolve_ref branch
      index.add path: path, oid: oid, mode: 0100644
      tree = index.write_tree @repo
      oid = commit ref, tree, msg
      @tree[branch] << oid
    end

    def read_file(branch, path)
      index, _ref = resolve_ref branch
      obj = index[path]
      fail IOError, "#{path} not found in branch #{branch}" unless obj
      blob = @repo.lookup obj[:oid]
      blob.content
    end

    def author
      {email: 'test@github.com', name: 'test'}
    end

    private

    def __init
      oid = @repo.write '', :blob
      index = @repo.index
      index.reload
      index.add path: '.init', oid: oid, mode: 0100644
      tree = index.write_tree @repo
      oid = __commit nil, tree, 'HEAD', 'init'
      @tree['master'] << oid
    end

    def resolve_ref(branch)
      ref = @repo.references["refs/heads/#{branch}"]
      index = @repo.index
      index.read_tree ref.target.tree
      [index, ref]
    end

    def __commit(target, tree, name, msg)
      options = {}
      options[:tree] = tree
      options[:author] = author
      options[:committer] = author
      options[:message] = msg
      options[:parents] = @repo.empty? ? [] : [target].compact
      options[:update_ref] = name

      oid = Rugged::Commit.create @repo, options
      @repo.checkout_head strategy: :force
      oid
    end

    def commit(ref, tree, msg)
      __commit ref.target, tree, ref.name, msg
    end
  end
end

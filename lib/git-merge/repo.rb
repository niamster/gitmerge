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

    def get_head(head)
      return @repo.head unless head
      unless @repo.branches.each_name(:local).include? head
        fail NotLocalHead, head
      end
      name = "refs/heads/#{head}"
      @repo.references[name]
    end

    def get_index(head)
      index = @repo.index
      index.read_tree(head.target.tree)
      index
    end
  end
end

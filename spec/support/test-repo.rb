module GitMerge::Test
  extend self

  def mk_file(repo, branch, name, ver=0)
    repo.write_file branch, "#{name}", "content of file #{name} v.#{ver}", "commit file #{name} v.#{ver}"
  end

  def mk_test_repo_0
    repo = Repo.new

    mk_file repo, 'master', 'test'
    repo.create_branch 'dev'
    repo.create_branch 'release'

    0.upto(2) do |idx|
      mk_file repo, 'master', idx.to_s
    end
    10.upto(12) do |idx|
      mk_file repo, 'dev', idx.to_s
    end
    mk_file repo, 'release', '0', 1
    mk_file repo, 'release', '20'

    repo
  end
end

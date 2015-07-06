RSpec.describe GitMerge do
  it "successfully merges branches withough conflicts" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox

    merge = GitMerge::Merge.new repo, branch: 'master'
    merge.merge! 'dev'

    10.upto(12) do |idx|
      expect(trepo.read_file('master', idx.to_s)).to eq("content of file #{idx} v.0")
    end
  end

  it "successfully merges branches with blocked conflicts" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox

    block = GitMerge::Block.new repo, branch: 'master'
    block.block! [trepo.tree['release'].first]

    merge = GitMerge::Merge.new repo, branch: 'master'
    merge.merge! 'release'

    expect(trepo.read_file('release', '0')).to eq("content of file 0 v.1")

    # newline is added by libgit2(bug https://github.com/libgit2/libgit2/issues/3294)
    expect(trepo.read_file('master', '0')).to eq("content of file 0 v.0\n")
  end

  it "does not fail if requested to blocked already blocked commits" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox

    block = GitMerge::Block.new repo, branch: 'master'
    block.block! [trepo.tree['release'].first]
    blocked = trepo.read_file('master', GitMerge::Block::BLOCKED)
    block.block! [trepo.tree['release'].first]
    expect(trepo.read_file('master', GitMerge::Block::BLOCKED)).to eq(blocked)
  end

  it "fails to merge branches with conflicts" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox

    merge = GitMerge::Merge.new repo, branch: 'master'

    expect { merge.merge!('release') }.to raise_error(GitMerge::MergeConflict)
    expect(File.open(File.join trepo.sandbox, '0').read).to eq(["<<<<<<< ours",
                                                                "content of file 0 v.0",
                                                                "=======",
                                                                "content of file 0 v.1",
                                                                ">>>>>>> theirs",
                                                                ""].join "\n")
  end
end

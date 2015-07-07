RSpec.describe GitMerge do
  it "successfully merges branches withough conflicts" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox, trepo.author

    merge = GitMerge::Merge.new repo, branch: 'master'
    merge.merge! 'dev'

    10.upto(12) do |idx|
      expect(trepo.read_file('master', idx.to_s)).to eq("content of file #{idx} v.0")
    end
  end

  it "successfully merges branches with blocked conflicts" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox, trepo.author

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
    repo = GitMerge::Repo.new trepo.sandbox, trepo.author

    block = GitMerge::Block.new repo, branch: 'master'
    block.block! [trepo.tree['release'].first]
    blocked = trepo.read_file('master', GitMerge::Block::BLOCKED)
    block.block! [trepo.tree['release'].first]
    expect(trepo.read_file('master', GitMerge::Block::BLOCKED)).to eq(blocked)
  end

  it "fails to merge branches with conflicts" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox, trepo.author

    merge = GitMerge::Merge.new repo, branch: 'master'

    expect { merge.merge!('release') }.to raise_error(GitMerge::MergeConflict)
    expect(File.open(File.join trepo.sandbox, '0').read).to eq(["<<<<<<< ours",
                                                                "content of file 0 v.0",
                                                                "=======",
                                                                "content of file 0 v.1",
                                                                ">>>>>>> theirs",
                                                                ""].join "\n")
  end

  it "fails to prepare for merge conflict resolution in dirty repo" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox, trepo.author

    merge = GitMerge::Merge.new repo, branch: 'master'

    expect { merge.merge!('release') }.to raise_error(GitMerge::MergeConflict)
    expect { merge.merge!('release') }.to raise_error(GitMerge::DirtyIndex)
  end

  it "fails to start merge if anothe merge is in progress" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox, trepo.author

    merge = GitMerge::Merge.new repo, branch: 'master'

    expect { merge.merge!('release') }.to raise_error(GitMerge::MergeConflict)
    trepo.checkout 'master', strategy: :force
    expect { merge.merge!('release') }.to raise_error(GitMerge::MergeInProgress)
  end

  it "fails to block or merge in non-local branch" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox, trepo.author

    block = GitMerge::Block.new repo, branch: 'origin/master'
    expect { block.block! [trepo.tree['release'].first] }.to raise_error(GitMerge::NotLocalHead)

    merge = GitMerge::Merge.new repo, branch: 'origin/master'
    expect { merge.merge!('release') }.to raise_error(GitMerge::NotLocalHead)
  end

  it "fails to merge from invalid branch" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox, trepo.author

    merge = GitMerge::Merge.new repo, branch: 'master'
    expect { merge.merge!('xxx') }.to raise_error(GitMerge::InvalidHead)
  end

  it "fails to block invalid commit" do
    trepo = GitMerge::Test.mk_test_repo_0
    repo = GitMerge::Repo.new trepo.sandbox, trepo.author

    block = GitMerge::Block.new repo, branch: 'master'
    expect { block.block! ['04d7ab73fe9dba72dbf8e87ae3de6678d41135e0'] }.to raise_error(GitMerge::InvalidCommit)
  end
end

RSpec.describe GitMerge::Test do
  it "creates test repo 0" do
    repo = GitMerge::Test.mk_test_repo_0

    0.upto(2) do |idx|
      expect(repo.read_file('master', idx.to_s)).to eq("content of file #{idx} v.0")
    end
    10.upto(12) do |idx|
      expect(repo.read_file('dev', idx.to_s)).to eq("content of file #{idx} v.0")
    end
    expect(repo.read_file('release', '0')).to eq("content of file 0 v.1")
    expect(repo.read_file('release', '20')).to eq("content of file 20 v.0")
  end
end

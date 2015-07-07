[![Coverage Status](https://coveralls.io/repos/niamster/gitmerge/badge.svg?branch=master)](https://coveralls.io/r/niamster/gitmerge?branch=master)
[![Build Status](https://secure.travis-ci.org/niamster/gitmerge.png?branch=master)](http://travis-ci.org/niamster/gitmerge)

# About
gitmerge is a helper utility that allows block particular commits during GIT merge.
Why one might need that? This is mainly useful when merging maintenance branches into the mainstream(master branch).
Depending on the workflow it's possible to have maintenance or customer-specific branches along with the master branch. These branches are also called LTS branches.
Oftentimes the hot fixes go into the branches where the bug was reported and then merged back into mainstream.
General practice is to have have all branches perfectly synchronized with the master,
i.e. you want to see a clear delta between a particular branch and master to understand whether the branch contains all features and bugfixes.
However sometimes you don't want particular commits because they are customer-specific and shall not be visible by other users. Or your master branch diverged that much that it requires completely different approach to fix the issue, or even better, the problem is not anymore present there.
Also this is handy in case of cherry-pick from master into the maintenance branch and thus that commit must be blocked in the branch from where it was picked.

### Installation
```
gem install gitmerge
```

### Usage
Assuming that current working directory is a working diroctory of GIT repository:
```
# block commits <commit-0> and <commit-1> in HEAD from <branch-0>
gitmerge block <commit-0> <commit-1>
# merge rest of <branch-0>
gitmerge merge <branch-0>
```

Gitmerge also supports blocking and merging without switching the branches(assuming no conflicts are possible):
```
# block commits <commit-0> and <commit-1> in <branch-1> from <branch-0>
gitmerge block -r /path/to/git-wd -b <branch-1> <commit-0> <commit-1>
# merge rest of <branch-0> into <branch-1>
gitmerge merge -r /path/to/git-wd -b <branch-1> <branch-0>
```
Consult the help for the full list of options.

### Conflicts
Gitmerge does not try to resolve merge conflicts but relies on the user(as during normal GIT merge).
Once the conflict is resolved it's probably required to rerun gitmerge to complete initial merge.

# License

MIT. See LICENSE file.

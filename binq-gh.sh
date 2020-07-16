#!/usr/bin/env bash
#
# Required Environment Variables:
# - GOOS: linux or darwin
# - GIT_USER: to commit git repo
# - GIT_EMAIL: to commit git repo
# - GITHUB_TOKEN: to update gh-pages branch of this repository

set -euo pipefail

WORK_DIR=work
BIN_DIR=${WORK_DIR}/bin
BINQ_GH=${BIN_DIR}/binq-gh
INDEX_REPO=${WORK_DIR}/index
export BINQ_BIN=${BIN_DIR}/binq
export BINQ_SERVER=https://binqry.github.io/index/

git_configure() {
  git config --global user.name $GIT_USER
  git config --global user.email $GIT_EMAIL
}

git_clone_index_repo() {
  local repo_url="https://${GIT_USER}:${GITHUB_TOKEN}@github.com/binqry/index.git"
  git clone $repo_url --branch=gh-pages --depth=1 $INDEX_REPO
}

install_binq() {
  pushd $BIN_DIR
  curl -s "https://raw.githubusercontent.com/binqry/binq/master/get-binq.sh" | bash
  popd
}

update_index_repo() {
  pushd ${INDEX_REPO}
  if ! git diff --quiet; then
    git add .
    git commit -m "Update by $(basename $0)"
    git push
    # TODO: notify Slack
  else
    echo "No diff on ${INDEX_REPO}. Nothing to do"
  fi
  popd
}

#============================================================
# Main Entry

echo "[START]"
mkdir -p $BIN_DIR

echo "[Exec] git configure"
git_configure
if [[ -d "${INDEX_REPO}" ]]; then
  echo "[Info] ${INDEX_REPO} already exists. Skip cloning repository"
else
  echo "[Exec] git clone index repository"
  git_clone_index_repo
fi

echo "[Exec] Install binq"
(
  install_binq
)
$BINQ_BIN binq-gh -L=info -d $BIN_DIR

for json in $(find ${INDEX_REPO}/github.com -name '*.json'); do
  echo "[Exec] binq-gh ${json}"
  $BINQ_GH $json --yes
done

echo "[Exec] Update index repository"
(
  update_index_repo
)

echo "[END]"

exit 0

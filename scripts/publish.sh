#!/usr/bin/env bash
# 一键发布 bii-blackrock-note → ClawHub + GitHub
#
# 用法：
#   bash scripts/publish.sh                # 干跑：只做体检与目标探测，不写远端
#   bash scripts/publish.sh --go           # 真发布
#   GITHUB_TOKEN=ghp_xxx bash scripts/publish.sh --go   # 需要新建 GitHub 仓库时必须带 token
#
# 设计约束（踩坑固化）：
#   · GitHub API 必须 --noproxy '*' 直连：本机 https_proxy 对 api.github.com 的 CONNECT 会 502。
#   · token 一律从环境变量读，**绝不写进本仓库**（本仓库是公开的）。
#   · 被取代的旧 slug 只做 hide（可 unhide 回滚），不做 delete。
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SLUG="bii-blackrock-note"
GH_USER="yjkj999999"
GH_REPO="bii-blackrock-note"
OLD_SLUG="brand-pdf-deck-replica"      # 本技能取代的旧技能
REPO_WORKDIR="${REPO_WORKDIR:-$HOME/Projects/$GH_REPO}"

GO=0
[[ "${1:-}" == "--go" ]] && GO=1

ok(){ printf '  \033[32m✔\033[0m %s\n' "$*"; }
no(){ printf '  \033[31m✘\033[0m %s\n' "$*"; }
hd(){ printf '\n\033[1m%s\033[0m\n' "$*"; }

# ── 0. 体检 ────────────────────────────────────────────────────────────────
hd "0. 发布前体检"
VER="$(awk -F': *' '/^version:/{print $2; exit}' "$SKILL_DIR/SKILL.md" | tr -d '"')"
NAME="$(awk -F': *' '/^name:/{print $2; exit}' "$SKILL_DIR/SKILL.md")"
[[ "$NAME" == "$SLUG" ]] && ok "name=$NAME" || { no "name=$NAME ≠ $SLUG"; exit 1; }
ok "version=$VER"
for f in SKILL.md README.md LICENSE docs/listing-card.md \
         assets/br_tokens.json assets/blackrock-theme.css \
         scripts/theme_inject.py scripts/check_br.py scripts/mkpptx.py \
         scripts/inspect_pages.sh scripts/pipeline.sh; do
  [[ -s "$SKILL_DIR/$f" ]] && ok "$f" || { no "缺失或空：$f"; exit 1; }
done
grep -q 'Microsoft YaHei\|<!DOCTYPE' "$SKILL_DIR/SKILL.md" && no "SKILL.md 疑似残留模板内容" || true
command -v clawhub >/dev/null && ok "clawhub $(clawhub --cli-version 2>/dev/null)" || { no "未安装 clawhub"; exit 1; }
AUTH="$(clawhub whoami 2>&1 | tail -1 | tr -d '\r')"
[[ "$AUTH" == *"$GH_USER"* ]] && ok "ClawHub 登录：$AUTH" || { no "ClawHub 未登录（clawhub login）"; exit 1; }

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  CODE="$(curl -s --noproxy '*' -o /tmp/.pb_gh.json -w '%{http_code}' \
    -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user)"
  [[ "$CODE" == "200" ]] && ok "GitHub token 有效（$(python3 -c "import json;print(json.load(open('/tmp/.pb_gh.json'))['login'])" 2>/dev/null)）" \
                        || no "GitHub token 无效（HTTP ${CODE}）——仓库若已存在可改走 SSH"
else
  no "未设 GITHUB_TOKEN —— 仅在仓库已存在时可用（走 SSH 推送）"
fi

if [[ $GO -eq 0 ]]; then
  hd "干跑结束（加 --go 真发布）"
  echo "  将执行："
  echo "    ① clawhub publish $SKILL_DIR --slug $SLUG --version $VER"
  echo "    ② clawhub hide $OLD_SLUG            # 退休旧技能（可 unhide）"
  echo "    ③ GitHub 建仓 ${GH_USER}/${GH_REPO}（若不存在）→ 同步 ${REPO_WORKDIR} → git push（SSH）"
  exit 0
fi

# ── 1. ClawHub ─────────────────────────────────────────────────────────────
hd "1. 发布到 ClawHub"
# 注意：新发布的技能会先进入审核态（hidden by moderation · pending.publication），
# 此时 clawhub inspect 会直接报错、读不到 Latest，所以**不能**靠 inspect 判断是否已发。
# 幂等判定改为：捕获 publish 输出，命中 "already exists" 即视为已发布。
PUB_OUT="$(clawhub publish "$SKILL_DIR" \
  --slug "$SLUG" \
  --name "BII 简报 × 贝莱德智库风格（pptx+pdf+html 三格式）" \
  --version "$VER" \
  --changelog "首个公开发布版。取代并退休 brand-pdf-deck-replica@1.0.1：把「品牌 PDF 复刻」的视觉体系与三格式交付管线，并入 BII 个股简报内容引擎。含 35 类色板重定向、七槽分类色相保真、装饰件零净增量约束、七门体检（含可见文本逐字零改动比对）。" \
  --tags "blackrock,bii,equity-note,pptx,pdf,html,deck,rebrand,a-share,research" 2>&1)"
PUB_RC=$?
printf '%s\n' "$PUB_OUT" | sed 's/^/    /' | tail -6
if [[ $PUB_RC -eq 0 ]]; then
  ok "ClawHub 发布完成：$SLUG@$VER"
elif printf '%s' "$PUB_OUT" | grep -q "already exists"; then
  ok "$SLUG@$VER 已在远端（审核态或已上架），跳过"
else
  no "ClawHub 发布失败"; exit 1
fi

hd "1b. 退休旧技能 $OLD_SLUG"
# 实测两种终态都会被 clawhub inspect 拒绝，必须分开识别，否则重跑会误报"已不在册"：
#   · 新发布但未过审 → "hidden by moderation (pending.publication)"
#   · 已 hide / 已删除 → "Skill not found"
HIDE_CHK="$(clawhub inspect "$OLD_SLUG" 2>&1)"
if printf '%s' "$HIDE_CHK" | grep -qi "hidden by moderation"; then
  ok "$OLD_SLUG 已处于隐藏态"
elif printf '%s' "$HIDE_CHK" | grep -qi "not found"; then
  ok "$OLD_SLUG 已不在册"
else
  clawhub hide --yes "$OLD_SLUG" && ok "已 hide ${OLD_SLUG}（clawhub unhide ${OLD_SLUG} 可回滚）" \
                                 || no "hide 失败（可稍后手动执行）"
fi

# ── 2. GitHub ──────────────────────────────────────────────────────────────
hd "2. 发布到 GitHub"
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  CHK="$(curl -s --noproxy '*' -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$GH_USER/$GH_REPO")"
  if [[ "$CHK" == "200" ]]; then
    ok "仓库已存在，跳过创建"
  else
    curl -s --noproxy '*' -X POST \
      -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" \
      -d "{\"name\":\"$GH_REPO\",\"description\":\"BII 个股简报 × 贝莱德智库风格 · 一条龙产出 pptx+pdf+html（内容零改动）\",\"homepage\":\"https://clawhub.ai/$GH_USER/skills/$SLUG\",\"private\":false,\"has_issues\":true,\"has_wiki\":false}" \
      https://api.github.com/user/repos > /tmp/.pb_create.json
    grep -q '"full_name"' /tmp/.pb_create.json && ok "仓库创建成功" \
      || { no "创建失败：$(head -c 200 /tmp/.pb_create.json)"; }
  fi
fi

mkdir -p "$REPO_WORKDIR"
rsync -a --delete --exclude '.git' --exclude '.DS_Store' --exclude '__pycache__' \
      --exclude '*.pyc' "$SKILL_DIR/" "$REPO_WORKDIR/"
ok "已同步技能内容 → $REPO_WORKDIR"

cd "$REPO_WORKDIR"
[[ -d .git ]] || git init -q -b main
git add -A
if git diff --cached --quiet; then
  ok "无变更，跳过提交"
else
  git -c user.name="${GIT_AUTHOR_NAME:-Wang Dongjie}" \
      -c user.email="${GIT_AUTHOR_EMAIL:-Wdj_@163.com}" \
      commit -q -m "feat: BII × 贝莱德智库风格 v${VER}（取代 brand-pdf-deck-replica）"
  ok "已提交"
fi
git remote get-url origin >/dev/null 2>&1 || git remote add origin "git@github.com:$GH_USER/$GH_REPO.git"
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git push -u origin main \
  && ok "已推送到 git@github.com:$GH_USER/$GH_REPO.git（SSH）" \
  || no "推送失败——确认仓库已存在且本机 SSH key 已加到 GitHub"

# ── 3. 复核 ────────────────────────────────────────────────────────────────
hd "3. 复核"
clawhub inspect "$SLUG" 2>&1 | head -8
echo ""
echo "  ClawHub : https://clawhub.ai/$GH_USER/skills/$SLUG"
echo "  GitHub  : https://github.com/$GH_USER/$GH_REPO"

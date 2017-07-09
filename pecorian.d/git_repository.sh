pecorian_git_repository_cmd() {

  # 2) select target
  local target="$( ghq list | pip_peco target )"
  local post_command=""
  # ここ共通
  [ -z "$target" ] && exit 1

  # 3) select action
  local action_list
  action_list=()
  action_list=(${action_list[@]} "cd")
  action_list=(${action_list[@]} "cd && open with explorer")
  action_list=(${action_list[@]} "cd && git pull origin master")
  action_list=(${action_list[@]} "open with browser")
  # ここ共通(actionは必ず配列から選択するので)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && exit 1

  if [ $action = "cd && open with explorer" ]; then
    local ghq_root=""
    if [ "$COMSPEC" != "" ]; then
      ghq_root="$( cygpath `ghq root` )" # Windowsの場合はスラッシュ表記に変更
      post_command="&& explorer ."
    else
      ghq_root="`ghq root`"
      post_command="&& open ."
    fi
    target=${ghq_root}/${target}
    action="cd"
  elif [ $action = "cd && git pull origin master" ]; then
    local ghq_root=""
    if [ "$COMSPEC" != "" ]; then
      ghq_root="$( cygpath `ghq root` )" # Windowsの場合はスラッシュ表記に変更
    else
      ghq_root="`ghq root`"
    fi
    target=${ghq_root}/${target}
    action="cd"
    post_command="&& git pull origin master"
  elif [ $action = "cd" ]; then
    local ghq_root=""
    if [ "$COMSPEC" != "" ]; then
      ghq_root="$( cygpath `ghq root` )" # Windowsの場合はスラッシュ表記に変更
    else
      ghq_root="`ghq root`"
    fi
    target=${ghq_root}/${target}
  elif [ $action = "open with browser" ]; then
    # http://qiita.com/itkrt2y/items/0671d1f48e66f21241e2
    target="$( echo $target | cut -d "/" -f 2,3 )"
    action="hub browse"
  fi

  # 4) return command
  echo "${action} ${target} ${post_command}"

  return
}
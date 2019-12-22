pecorian_tmux_cmd() {

  # 2) select target
  local targets_list
  targets_list=()
  # docker-composeが使える場合のみdocker-composeで管理されているコンテナを対象とする

  local targets="`tmux ls`"
  local create_new_session="create new session:"
  local create_new_session_displayed="'create new session'"
  if [ -z $targets ]; then
    targets="${create_new_session}"
  else
    if [ -z $TMUX ]; then
      targets="${targets}\n${create_new_session}"
    fi
  fi
  local target="$( echo $targets | pip_peco target | cut -d: -f1)"
  # common process
  target="'${target}'"
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  if [ $target != $create_new_session_displayed ]; then
    local action_list
    action_list=()
    if [ -z $TMUX ]; then
      action_list=(${action_list[@]} "attach")
    fi
    action_list=(${action_list[@]} "rename")
    action_list=(${action_list[@]} "kill")
    # common process ("action" is always selected from array)
    local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
    [ -z "$action" ] && pecorian_abort
  fi

  # 4) create command
  if [ $target = $create_new_session_displayed ]; then
    action="tmux"
    target=""
  elif [ $action = "attach" ]; then
      action="tmux a -t"
  elif [ $action = "rename" ]; then
      action="tmux rename -t"
  elif [ $action = "kill" ]; then
      action="tmux kill-session -t"
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}

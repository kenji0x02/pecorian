pecorian_conda_cmd() {

  # 2) select target
  # #で始まる行はコメントなのでgrepで削除
  # なぜか空白行が含まれるので削除
  # ターゲットとしてのすべての環境を追加
  # 1列目のみを仮想環境名として抽出
  local target="$( conda info -e | grep -v \# | sed -e '/^[<space><tab>]*$/d' | sed -e '$ a All_virtual_environment' | pip_peco target | cut -d" " -f1)"
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  if [ $target != "All_virtual_environment" ]; then
    action_list=(${action_list[@]} "list installed packages")
    action_list=(${action_list[@]} "activate")
    action_list=(${action_list[@]} "deactivate")
    action_list=(${action_list[@]} "remove")
    action_list=(${action_list[@]} "export")
  else
    action_list=(${action_list[@]} "remove ALL unused packages and caches")
    action_list=(${action_list[@]} "update conda")
    action_list=(${action_list[@]} "update anaconda")
    action_list=(${action_list[@]} "create an environment")
  fi
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  if [ $action = "list installed packages" ]; then
    action="conda list --name"
    post_command="| peco" # 多いので絞り込めるように
  elif [ $action = "activate" ]; then
    local ghq_root=""
    if pecorian_is_windows_os; then
      action="source activate"
    else
      action="activate"
    fi
  elif [ $action = "deactivate" ]; then
    local ghq_root=""
    if pecorian_is_windows_os; then
      action="source deactivate"
    else
      action="deactivate"
    fi
    target=""
  elif [ $action = "remove" ]; then
    action="conda remove --name"
    post_command="--all"
  elif [ $action = "export" ]; then
    action="conda env export --name"
    post_command="> ${target}.yaml"
  elif [ $action = "remove ALL unused packages and caches" ]; then
    action="conda clean --all"
    target=""
  elif [ $action = "update conda" ]; then
    action="conda update conda"
    target=""
  elif [ $action = "update anaconda" ]; then
    action="conda update anaconda"
    target=""
  elif [ $action = "create an environment" ]; then
    action="conda create --name NEW_ENVIRONMENT_NAME python=3.6"
    target=""
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}

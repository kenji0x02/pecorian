pecorian_trush_cmd() {

  # 2) select target
  local target=" " # need dummy space not to abort
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  action_list=(${action_list[@]} "remove")
  action_list=(${action_list[@]} "open with explorer")
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  if [ $action = "remove" ]; then
    if pecorian_is_windows_os; then
      local action='rm -R /c/\$Recycle.Bin/ 2>/dev/null'
    else
      local action='rm -rf ~/.Trash/'
    fi
  elif [ $action = "open with explorer" ]; then
    if pecorian_is_windows_os; then
      # shellコマンドで特殊フォルダをエクスプローラーで開く
      local action="explorer shell:RecycleBinFolder"
    else
      local action="open ~/.Trash/"
    fi
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}
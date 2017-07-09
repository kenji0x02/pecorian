pecorian_current_dir_cmd() {

  # 2) select target
  local target=""
  case $1 in
    1)
  # カレントディレクトリ[.]と親ディレクトリ[..]を表示しない(Aオプション)
  # エイリアスを外して、ディレクトリは/をつけて表示(Fオプション)
      if pecorian_is_mac_os; then
        target="$( \ls -AF | pip_peco target )"
      else
        target="$( \ls -AF --group-directories-first | pip_peco target )"
      fi
      ;;
    2)
      # findは難しい、http://takuya-1st.hatenablog.jp/entry/20110918/1316338219
      target="$( find . -maxdepth 2 -type d -name '.git' -prune -o -print | pip_peco target )"
      ;;
    3)
      target="$( find . -maxdepth 3 -type d -name '.git' -prune -o -print | pip_peco target )"
      ;;
    "all")
      target="$( find . -type d -name '.git' -prune -o -print | pip_peco target )"
      ;;
    *)
      target=""
  esac

  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  # todo: ドットファイルがディレクトリとして認識される
  local eval_target="$(eval "echo $target")"

  if [ -d $eval_target ]; then
    action_list=(${action_list[@]} "cd")
    action_list=(${action_list[@]} "ls -al")
    action_list=(${action_list[@]} "rm -rf")
    action_list=(${action_list[@]} "mv")
    action_list=(${action_list[@]} "cp")
    # 空白文字列を含む場合は""で囲う
    if [[ "$target" =~ " " ]]; then
      target="\"${target}\""
    fi
  else
    # ディレクトリじゃないときのコマンドリスト
    action_list=(open vi mv rm cp ls cat less) # openコマンドは自前で実装
  fi
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  # do nothing

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}
# helper
pip_peco()
{
  peco --prompt="$1 >" --on-cancel error
}

pecorian_abort()
{
  IFS=$PECORIAN_IFS_BACKUP
  exit 1
}

pecorian_is_windows_os()
{
  [ "$COMSPEC" != "" ]
}

pecorian_is_mac_os()
{
  [ `uname` '==' 'Darwin' ]
}

export PECORIAN_IFS_BACKUP=$IFS

# main
pecorian_cmd() {
  # 配列に半角スペースを許す
  IFS=$'\n'

  # 1) select scope
  scope_list=()

  # 常に追加
  local scope_history="History"
  scope_list=(${scope_list[@]} $scope_history)

  local scope_current_dir="Current dir"
  local scope_current_dir_all_sub_dir="Current dir + all sub dir"
  scope_list=(${scope_list[@]} $scope_current_dir)
  scope_list=(${scope_list[@]} $scope_current_dir_all_sub_dir)

  local scope_process="Process"
  scope_list=(${scope_list[@]} $scope_process)

  local scope_path="Path"
  scope_list=(${scope_list[@]} $scope_path)

  if pecorian_is_windows_os || pecorian_is_mac_os; then 
    local scope_trush="Trush"
    scope_list=(${scope_list[@]} $scope_trush)
  fi

  # dockerコマンドが存在した場合のみ表示
  # whichコマンドで探すよりも組込みコマンドのtypeの方が速いらしい
  # http://qiita.com/kawaz/items/1b61ee2dd4d1acc7cc94
  if type "docker" > /dev/null 2>&1; then
    # need to start docker for windows
    if pecorian_is_windows_os; then
      if [ "$DOCKER_HOST" != "" ]; then
        if [ -n "$(docker ps -a --format {{.ID}})" ]; then
          local scope_docker_container="Docker a container"
          scope_list=(${scope_list[@]} $scope_docker_container)
        fi
      fi
    else
      if [ -n "$(docker ps -a --format {{.ID}})" ]; then
        local scope_docker_container="Docker a container"
        scope_list=(${scope_list[@]} $scope_docker_container)
      fi
    fi
  fi

  if type "docker" > /dev/null 2>&1; then
    if pecorian_is_windows_os; then
      if [ "$DOCKER_HOST" != "" ]; then
        local scope_docker="Docker containers/images"
        scope_list=(${scope_list[@]} $scope_docker)
      fi
    else
      local scope_docker="Docker containers/images"
      scope_list=(${scope_list[@]} $scope_docker)
    fi
  fi

  if type "tmux" > /dev/null 2>&1; then
    local scope_tmux="Tmux"
    scope_list=(${scope_list[@]} $scope_tmux)
  fi

  local scope=$( for s in ${scope_list[@]}; do echo $s; done | pip_peco scope )
  [ -z "$scope" ] && pecorian_abort

  # create command for each scope
  case $scope in
    $scope_history)
      if [ "$SHELL" = '/bin/zsh' ]; then
        pecorian_select_history_zsh
      elif [ "$SHELL" = '/bin/bash' ]; then
        pecorian_select_history_bash
      else
        echo "[Error] history command not found."
      fi
      ;;
    $scope_current_dir)
      pecorian_current_dir_cmd 1
      ;;
    $scope_current_dir_all_sub_dir)
      pecorian_current_dir_cmd all
      ;;
    $scope_process)
      pecorian_process_cmd
      ;;
    $scope_path)
      pecorian_path_cmd
      ;;
    $scope_trush)
      pecorian_trush_cmd
      ;;
    $scope_docker_container)
      pecorian_docker_container_cmd
      ;;
    $scope_docker)
      pecorian_docker_cmd
      ;;
    $scope_tmux)
      pecorian_tmux_cmd
      ;;
    *)
      exit 1
  esac

  IFS=$PECORIAN_IFS_BACKUP

  return
}

# main
pecorian_zsh() {
  local cmd="`pecorian_cmd`"
  BUFFER="$cmd"
  CURSOR=${#BUFFER}
  zle clear-screen
}

pecorian_bash() {
  local cmd=`pecorian_cmd`
  READLINE_LINE="$cmd"
  READLINE_POINT=${#cmd}
}

if [ "$SHELL" = '/bin/zsh' ]; then
  zle -N pecorian_zsh
  bindkey '\C-j' pecorian_zsh
elif [ "$SHELL" = '/bin/bash' ]; then
  bind -x '"\C-j": pecorian_bash'
else
  echo "[Error] Shell must be bash or zsh. Current shell: $SHELL"
fi

# pecoで履歴検索
# oh-my-zshでエイリアスが設定されているので
unalias history > /dev/null 2>&1
pecorian_select_history_zsh() {
    local tac
    if which tac > /dev/null; then
        tac="tac"
    else
        tac="tail -r"
    fi
    # -i:日時表示あり, -n:連番なし, 1:1行目から表示(全ての履歴を表示)
    # sedの正規表現では空白行を\sでは表現できないので空白行を直接入力する
    history -in 1 | eval $tac | peco | sed -e 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\} *//'
}

pecorian_select_history_bash() {
  export HISTTIMEFORMAT="%Y-%m-%d %R  " # 出力フォーマットの指定
  # 履歴表示 | 降順 | 履歴通し番号削除 | 重複行削除 | peco | 日時削除
  # sedの正規表現では空白行を\sでは表現できないので空白行を直接入力する
  # 重複行削除時に日時の列($1, $2)を除いた後半部分(とりあえず3,4,5,6列目)をキーとして使用
  echo $( history | tac | sed -e 's/^\s*[0-9]\+\s\+//' | awk '!a[$3 $4 $5 $6]++' | peco --query "$READLINE_LINE" | sed -e 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\} *//')
}

# current dir
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
    action_list=(vi mv rm cp ls cat less)
  fi
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  # 空白文字列を含む場合は""で囲う
  if [[ "$target" =~ " " ]]; then
    target="\"${target}\""
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}
# git
# todo: git repositoryに対してコマンド操作


# process
pecorian_process_cmd() {

  # 2) select target
  local target=""
  if pecorian_is_windows_os; then
    target="$( tasklist | pip_peco target | awk '{print $2}')"
  else
    target="$( ps aux | pip_peco target | awk '{print $2}')"
  fi
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  if pecorian_is_mac_os; then
    action_list=(${action_list[@]} "kill")
  else
    action_list=(${action_list[@]} "kill")
    action_list=(${action_list[@]} "show detail")
  fi
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  if [ $action = "kill" ]; then
    if pecorian_is_windows_os; then
      local action="taskkill -f -pid"
    else
      local action="kill"
    fi
  elif [ $action = "show detail" ]; then
    if pecorian_is_windows_os; then
      local action="wmic process where ProcessID=${target} get Name,ProcessId,CommandLine /format:list"
    else
      local action="sudo ls --color -al /proc/${target}"
    fi
    target=""
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}

# path
pecorian_path_cmd() {

  # 2) select target
  local target="$( echo $PATH | tr ':' '\n' | pip_peco target )"
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  action_list=(${action_list[@]} "cd")
  action_list=(${action_list[@]} "ls -al")
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  # 空白文字列を含む場合は""で囲う
  if [[ "$target" =~ " " ]]; then
    target="\"${target}\""
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}

# trush
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

# docker container
pecorian_docker_container_cmd() {

  # 2) select target
  # 空白カラムが存在するケースがあるのでNAMES属性はとれない
  local target="$( docker ps -a | tail -n +2 | pip_peco target | cut -d" " -f1 )"
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  local is_running="$(docker ps -a -f id=$target -f status=running --format {{.ID}})"
  if [ $is_running != "" ]; then
    # 起動しているコンテナに対するアクション
    action_list=(${action_list[@]} "log")
    action_list=(${action_list[@]} "exec (run a new command in a running container)")
    action_list=(${action_list[@]} "attach (connect to PID=1 process)")
    action_list=(${action_list[@]} "top (display the running processes outside the containter)")
    action_list=(${action_list[@]} "stop")
  else
    action_list=(${action_list[@]} "log")
    action_list=(${action_list[@]} "start")
    action_list=(${action_list[@]} "remove")
    action_list=(${action_list[@]} "commit")
  fi
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  if [ $action = "start" ]; then
    local action="docker start"
  elif [ $action = "stop" ]; then
    local action="docker stop"
  elif [ $action = "log" ]; then
    local action="docker logs -tf --tail=100" # -t:時間も表示, -f(--folow):ログを出力し続ける, --tail=100:最終行から100行遡る
  elif [ $action = "exec (run a new command in a running container)" ]; then
    local action="docker exec -it" # -i:interactive, -t:tty
    # post_command="ps -aux" # 例)プロセスを表示
    post_command="bash" # 例)bashでログイン
  elif [ $action = "attach (connect to PID=1 process)" ]; then
    local action="docker attach"
  elif [ $action = "top (display the running processes outside the containter)" ]; then
    local action="docker top"
    post_command="| unexpand -t20" # 少々見にくいので整形して表示
  elif [ $action = "remove" ]; then
    local action="docker rm"
  elif [ $action = "commit" ]; then
    local action="docker commit"
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}

# docker
pecorian_docker_cmd() {

  # 2) select target
  local targets_list
  targets_list=()
  # docker-composeが使える場合のみdocker-composeで管理されているコンテナを対象とする
  if [ -e "docker-compose.yml" ] || [ -e "docker-compose.yaml" ]; then
    targets_list=(${targets_list[@]} "containers managed by Compose")
  fi
  targets_list=(${targets_list[@]} "containers stopped")
  targets_list=(${targets_list[@]} "containers all")
  targets_list=(${targets_list[@]} "containers up")
  targets_list=(${targets_list[@]} "images that is not used in all containers")
  targets_list=(${targets_list[@]} "images that is not tagged (i.e. <none>:<none>)")
  target="$( for s in ${targets_list[@]}; do echo $s; done | pip_peco target )"
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  if [ $target = "containers managed by Compose" ]; then
    action_list=(${action_list[@]} "build, create and start") # サービスを構築(build)して、コンテナ作成(create)と開始(start)
    action_list=(${action_list[@]} "logs") # 関係するコンテナのすべての出力を表示
    action_list=(${action_list[@]} "stop")
    action_list=(${action_list[@]} "remove")
    action_list=(${action_list[@]} "down(stop and rm service) and delete images") # 関係するコンテナをまとめて停止して削除
    action_list=(${action_list[@]} "ps") # 関係するコンテナの一覧表示
    action_list=(${action_list[@]} "restart") # 関係するコンテナの再起動
  elif [ $target = "containers up" ]; then
    action_list=(${action_list[@]} "statistics")
  else
    action_list=(${action_list[@]} "remove")
  fi
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  if [ $target = "containers managed by Compose" ]; then
    if [ $action = "build, create and start" ]; then
      action="docker-compose up -d --build"
    elif [ $action = "logs" ]; then
      action="docker-compose logs -tf" # t: time, f: follow
    elif [ $action = "stop" ]; then
      action="docker-compose stop"
    elif [ $action = "remove" ]; then
      action="docker-compose rm"
    elif [ $action = "down(stop and rm service) and delete images" ]; then 
      action="docker-compose down --rmi all"
    elif [ $action = "ps" ]; then
      action="docker-compose ps"
    elif [ $action = "restart" ]; then
      action="docker-compose restart"
    else
      action=""
    fi
    target=""
  elif [ $target = "containers up" ]; then
    if [ $action = "statistics" ]; then
      action="docker stats"
    else
      action=""
    fi
    target=""
  else
    if [ $action = "remove" ]; then
      if [ $target = "containers stopped" ]; then
        local action="docker container prune" #prune: 刈り込む
      elif [ $target = "containers all" ]; then
        local action='docker rm -f $(docker ps -aq)'
      elif [ $target = "images that is not used in all containers" ]; then
        local action="docker images prune" #prune: 刈り込む
      elif [ $target = "images that is not tagged (i.e. <none>:<none>)" ]; then
        local action='docker rmi $(docker images -aqf 'dangling=true')' #dangling: ぶら下がる
      else
        local action=""
      fi
      target=""
    fi
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}

# tmux
pecorian_tmux_cmd() {

  # 2) select target
  local targets_list
  targets_list=()

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

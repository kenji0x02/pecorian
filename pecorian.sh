
pecorian() {
    # 配列に半角スペースを許す
    IFS_BACKUP=$IFS
    IFS=$'\n'

    # 1) select scope 
    local scope_current_dir="Current dir"
    local scope_current_dir_below2="Current dir below depth 2"
    local scope_current_dir_below3="Current dir below depth 3"
    local scope_current_dir_below_all="Current dir below depth all"
    local scope_favorite="Favorite"
    local scope_recent="Recently used"
    local scope_git_rep="Git repository(ghq)"
    local scope_process="Process"
    local scope_path="Path"
    local scope_trush="Trush"

    local scope_list
    scope_list=()
    scope_list=(${scope_list[@]} $scope_current_dir)
    scope_list=(${scope_list[@]} $scope_current_dir_below2)
    scope_list=(${scope_list[@]} $scope_current_dir_below3)
    scope_list=(${scope_list[@]} $scope_current_dir_below_all)
    scope_list=(${scope_list[@]} $scope_favorite)
    scope_list=(${scope_list[@]} $scope_recent)
    scope_list=(${scope_list[@]} $scope_git_rep)
    scope_list=(${scope_list[@]} $scope_process)
    scope_list=(${scope_list[@]} $scope_path)
    scope_list=(${scope_list[@]} $scope_trush)
    
    local scope="$( for s in ${scope_list[@]}; do echo $s; done | peco --prompt="scope >")"

    # 2) select target
    # todo: 新規作成のフロー新規作成ファイル名を指定？？
    local target=""
    local post_command=""
    case $scope in
        $scope_current_dir)
	    # カレントディレクトリ[.]と親ディレクトリ[..]を表示しない(Aオプション)
            target="$( \ls -AF --group-directories-first | peco --prompt="target >")" # エイリアスを外して、ディレクトリは/をつけて表示(Fオプション)
            ;;
	$scope_current_dir_below2)
	    # findは難しい、http://takuya-1st.hatenablog.jp/entry/20110918/1316338219
            target="$( find . -maxdepth 2 -type d -name '.git' -prune -o -print | peco --prompt="target >")"
            ;;
	$scope_current_dir_below3)
            target="$( find . -maxdepth 3 -type d -name '.git' -prune -o -print | peco --prompt="target >")"
            ;;
	$scope_current_dir_below_all)
            target="$( find . -type d -name '.git' -prune -o -print | peco --prompt="target >")"
            ;;
	$scope_favorite)
            target="$( cat ~/.dir_favorite | head -n $((LINES - 3)) | peco --prompt="target >")"
            ;;
	$scope_recent)
	    # とりあえず1行捨てるバージョンで表示
            target="$( tac ~/.dir_history | sed '1d' | awk '!a[$0]++' | head -n $((LINES - 3)) | peco --prompt="target >")"
            ;;
	$scope_git_rep)
            target="$( ghq list | peco --prompt="target >")"
            ;;
	$scope_process)
            if [ "$COMSPEC" != "" ]; then
              target="$( tasklist | peco --prompt="target >"| awk '{print $2}')"
            else
              target="$( ps aux | peco --prompt="target >"| awk '{print $2}')"
            fi
            ;;
	$scope_path)
            target="$( echo $PATH | tr ':' '\n' | peco --prompt="target >")"
            ;;
	$scope_trush)
            target=""
            ;;
        *) # 上記以外
            target="$( \ls -AF --group-directories-first | peco --prompt="target >")" # エイリアスを外して、ディレクトリは/をつけて表示
    esac

    # 3) select action
    local action_list
    action_list=()
    # todo: ドットファイルがディレクトリとして認識される
    local eval_target="$(eval "echo $target")"
    if [ $scope = $scope_git_rep ]; then
        action_list=(${action_list[@]} "cd && open with explorer")
        action_list=(${action_list[@]} "cd")
        action_list=(${action_list[@]} "open with browser")
    elif [ $scope = $scope_process ]; then action_list=(${action_list[@]} "kill")
        action_list=(${action_list[@]} "show detail")
    elif [ $scope = $scope_trush ]; then
        action_list=(${action_list[@]} "remove")
        action_list=(${action_list[@]} "open with explorer")
    elif [ -d $eval_target ]; then
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
        local action_list=(open vi mv rm cp ls cat less) # openコマンドは自前で実装
    fi

    local action="$(for e in ${action_list[@]}; do echo $e; done | peco --prompt="action >")"

    if [ $scope = $scope_git_rep ]; then
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
    elif [ $scope = $scope_process ]; then
        if [ $action = "kill" ]; then
            if [ "$COMSPEC" != "" ]; then
              local action="taskkill -f -pid"
            else
              local action="kill"
            fi
        elif [ $action = "show detail" ]; then
            if [ "$COMSPEC" != "" ]; then
              local action="wmic process where ProcessID=${target} get Name,ProcessId,CommandLine /format:list"
            else
              local action="sudo ls --color -al /proc/${target}"
            fi
	    target=""
	fi
    elif [ $scope = $scope_trush ]; then
        if [ $action = "remove" ]; then
	    local action='rm -R /c/\$Recycle.Bin/ 2>/dev/null'
        elif [ $action = "open with explorer" ]; then
	    # shellコマンドで特殊フォルダをエクスプローラーで開く
	    local action="explorer shell:RecycleBinFolder"
	fi
    fi

    # 4) select option target

    # 5) finalize
    local cmd="${action} ${target} ${post_command}"
    IFS=$IFS_BACKUP

    if [ "$COMSPEC" != "" ]; then
      READLINE_LINE="$cmd"
      READLINE_POINT=${#cmd}
    else
      BUFFER="$cmd"
      CURSOR=${#BUFFER}
    fi
}


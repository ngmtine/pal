#!/bin/bash

# プロセスIDを格納するファイル
PID_FILE="/tmp/pal.pid"
ORIGINAL_PID_FILE="/tmp/original_pid"

# 起動する関数
start() {
    if [ -f "$PID_FILE" ]; then
        echo "Process is already running."
        exit 1
    fi
    
    # 現在のPIDを保存
    echo $$ > "$ORIGINAL_PID_FILE"
    
    # 引数で受け取ったプログラムをバックグラウンドで起動し、プロセスIDを保存
    "$1" &
    child_pid=$!
    echo $child_pid > "$PID_FILE"
    
    # Process started with PID の表示を先に行う
    echo "Process started with PID $child_pid"
    
    # PIDファイルが存在する間は、終了シグナルをトラップしてプロセスを停止
    trap 'stop; exit 0' SIGINT
    trap 'restart' SIGHUP
    wait $child_pid
}

# 停止する関数
stop() {
    if [ ! -f "$PID_FILE" ]; then
        echo "No process is running."
        exit 1
    fi
    
    # プロセスを停止し、PIDファイルを削除
    kill "$(cat $PID_FILE)" && rm -f "$PID_FILE"
    echo "Process stopped."
}

# 再起動する関数
restart() {
    echo "Restarting process..."
    stop
    start "$program"
}

# コマンドライン引数に応じて動作
case "$1" in
    start)
        program="$2"
        start "$program"
    ;;
    stop)
        stop
    ;;
    restart)
        # 自身にSIGHUPシグナルを送信
        if [ -f "$ORIGINAL_PID_FILE" ]; then
            kill -SIGHUP "$(cat $ORIGINAL_PID_FILE)"
        fi
    ;;
    *)
        echo "Usage: $0 {start|stop|restart} <program>"
        exit 1
    ;;
esac

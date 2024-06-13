#!/bin/bash

# プロセスIDを格納するファイル
PID_FILE="/tmp/pal.pid"
OUTPUT_FILE="/tmp/pal_output.log"
TAIL_PID_FILE="/tmp/tail_pal.pid"
ORIGINAL_TTY_FILE="/tmp/original_tty"
ORIGINAL_PID_FILE="/tmp/original_pid"

# 起動する関数
start() {
    if [ -f "$PID_FILE" ]; then
        echo "Process is already running."
        exit 1
    fi
    
    # 現在のTTYとPIDを保存
    tty > "$ORIGINAL_TTY_FILE"
    echo $$ > "$ORIGINAL_PID_FILE"
    
    # ログファイルをクリア
    > "$OUTPUT_FILE"
    
    # 引数で受け取ったプログラムをバックグラウンドで起動し、プロセスIDを保存
    "$1" >> "$OUTPUT_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo "Process started with PID $(cat $PID_FILE)"
    
    # ログファイルの内容をリアルタイムで表示
    tail -f "$OUTPUT_FILE" &
    echo $! > "$TAIL_PID_FILE"
    
    # PIDファイルが存在する間は、終了シグナルをトラップしてプロセスを停止
    trap 'stop; exit 0' SIGINT
    trap 'restart_tail' SIGUSR1
    wait "$(cat $PID_FILE)"
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
    
    # tailプロセスも停止し、PIDファイルを削除
    if [ -f "$TAIL_PID_FILE" ]; then
        kill "$(cat $TAIL_PID_FILE)" 2>/dev/null && rm -f "$TAIL_PID_FILE"
    fi
    
    # TTYファイルとPIDファイルを削除
    rm -f "$ORIGINAL_TTY_FILE" "$ORIGINAL_PID_FILE"
}

# 再起動する関数
restart() {
    if [ ! -f "$PID_FILE" ]; then
        echo "No process is running."
        exit 1
    fi
    
    # 現在のTTYを取得
    original_tty=$(cat "$ORIGINAL_TTY_FILE")
    original_pid=$(cat "$ORIGINAL_PID_FILE")
    
    # プロセスを停止し、再起動
    stop "$1"
    start "$1" > /dev/null &
    
    # 再起動したことを通知
    echo "Process restarted."
    
    # 元のTTYにシグナルを送信してtailを再実行
    if [ "$(tty)" != "$original_tty" ]; then
        kill -SIGUSR1 "$original_pid"
    fi
}

# tailを再実行する関数
restart_tail() {
    if [ -f "$TAIL_PID_FILE" ]; then
        kill "$(cat $TAIL_PID_FILE)" 2>/dev/null && rm -f "$TAIL_PID_FILE"
    fi
    tail -f "$OUTPUT_FILE" &
    echo $! > "$TAIL_PID_FILE"
}

# コマンドライン引数に応じて動作
case "$1" in
    start)
        start "$2"
    ;;
    stop)
        stop "$2"
    ;;
    restart)
        restart "$2"
    ;;
    *)
        echo "Usage: $0 {start|stop|restart} <program>"
        exit 1
    ;;
esac

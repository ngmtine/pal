### pal: process and application launcher

端末 A から start したプロセスを端末 B で stop したり restart したりするやつ  
名前は適当

```sh
chmod +x pal.sh
chmod +x main.sh
```

```sh
./pal.sh start ./main.sh
./pal.sh restart ./main.sh
./pal.sh stop ./main.sh
```

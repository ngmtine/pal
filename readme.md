### pal: process and log Manager

端末 A から start したプロセスを端末 B で stop したり restart したりするやつ  
名前は適当

```sh
chmod +x pal.sh
chmod +x mock.sh
```

```sh
./pal.sh start ./mock.sh
./pal.sh restart ./mock.sh
./pal.sh stop ./mock.sh
```

### todo

・別端末で restart した場合に元端末で tail が実行されない

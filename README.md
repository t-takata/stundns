stundns
====

DNS クエリのソース IP を A/AAAA/TXT で応答する DNS もどきサーバです。

```sh
$ dig @192.168.1.24 -p 5300 +norec stundns.internal. a

; <<>> DiG 9.11.3-1ubuntu1.5-Ubuntu <<>> @192.168.1.24 -p 5300 +norec stundns.internal. a
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 6982
;; flags: qr aa; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;stundns.internal.              IN      A

;; ANSWER SECTION:
stundns.internal.       0       IN      A       192.168.1.30

;; Query time: 2 msec
;; SERVER: 192.168.1.24#5300(192.168.1.24)
;; WHEN: Sat Mar 02 14:00:21 DST 2019
;; MSG SIZE  rcvd: 50
```

```sh
$ dig @192.168.1.24 -p 5300 +norec stundns.internal. txt

; <<>> DiG 9.11.3-1ubuntu1.5-Ubuntu <<>> @192.168.1.24 -p 5300 +norec stundns.internal. txt
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29237
;; flags: qr aa; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;stundns.internal.              IN      TXT

;; ANSWER SECTION:
stundns.internal.       0       IN      TXT     "192.168.1.30 54820"

;; Query time: 1 msec
;; SERVER: 192.168.1.24#5300(192.168.1.24)
;; WHEN: Sat Mar 02 14:00:24 DST 2019
;; MSG SIZE  rcvd: 65
```

## Usage

```sh
$ ./stundns --help
Usage: stundns [options]
    -l LISTENIP[:PORT[/(udp/tcp)]]   Listen IP:Port/Protocol (default: 0.0.0.0:5300)
    -a RECORD                        FQDN(or /Regex/) to respond the A/AAAA record. (default: stundns.internal)
    -t RECORD                        FQDN(or /Regex/) to respond the TXT record. (default: stundns.internal)
```

```sh
## 普通に起動
$ ./stundns
I, [2019-03-02T05:21:29.215573 #1]  INFO -- : Starting RubyDNS server (v1.0.3)...
I, [2019-03-02T05:21:29.215636 #1]  INFO -- : <> Listening on udp:0.0.0.0:5300
I, [2019-03-02T05:21:29.217703 #1]  INFO -- : <> Listening on tcp:0.0.0.0:5300
====
(問い合わせ例)
$ dig @192.168.1.24 -p 5300 +norec +short stundns.internal. txt
"192.168.1.30 52082"
```

```sh
## どのような FQDN を問い合わせられてもソース IP を応答するとき (正規表現を使う)
$ ./stundns -a /.*/ -t /.*/
I, [2019-03-02T05:13:56.783100 #1]  INFO -- : Starting RubyDNS server (v1.0.3)...
I, [2019-03-02T05:13:56.783161 #1]  INFO -- : <> Listening on udp:0.0.0.0:5300
I, [2019-03-02T05:13:56.783793 #1]  INFO -- : <> Listening on tcp:0.0.0.0:5300
====
(問い合わせ例)
$ dig @192.168.1.24 -p 5300 +norec +short hoge.fuga.example.jp. txt
"192.168.1.30 54816"
$ dig @192.168.1.24 -p 5300 +norec +short foo.bar.example.com. txt
"192.168.1.30 55542"
```

```sh
## IPv6 でも Listen するとき
$ ./stundns -l [::]:5301
I, [2019-03-02T05:17:12.483095 #1]  INFO -- : Starting RubyDNS server (v1.0.3)...
I, [2019-03-02T05:17:12.483174 #1]  INFO -- : <> Listening on udp::::5301
I, [2019-03-02T05:17:12.483991 #1]  INFO -- : <> Listening on tcp::::5301
====
(問い合わせ例)
$ dig @2001:db8::24 -p 5301 +norec +short stundns.internal. txt
"2001:db8::31 57829"
```

```sh
## 各オプションは複数回指定可能
$ ./stundns -l 0.0.0.0:5300/udp -l [::]:5301/tcp -t hoge.internal -t fuga.internal
I, [2019-03-02T05:23:08.515065 #1]  INFO -- : Starting RubyDNS server (v1.0.3)...
I, [2019-03-02T05:23:08.515123 #1]  INFO -- : <> Listening on udp:0.0.0.0:5300
I, [2019-03-02T05:23:08.520976 #1]  INFO -- : <> Listening on tcp::::5301
====
$ ss -an | grep :530
udp    UNCONN     0      0         *:5300                  *:*
tcp    LISTEN     0      128      :::5301                 :::*
====
(問い合わせ例)
$ dig @192.168.1.24 -p 5300 +norec +short stundns.internal. txt
$ dig @192.168.1.24 -p 5300 +norec +short hoge.internal. txt
"192.168.1.30 49518"
$ dig @192.168.1.24 -p 5300 +norec +short fuga.internal. txt
"192.168.1.30 49521"
```

## Licence

[MIT](https://github.com/t-takata/stundns/blob/master/LICENSE)

## Author

[t-takata](https://github.com/t-takata)

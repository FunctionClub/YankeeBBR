# YankeeBBR
来自Loc大佬Yankee魔改的BBR的Debian一键安装包

## 安装命令
```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/FunctionClub/YankeeBBR/master/bbr.sh && bash bbr.sh install
```

然后根据提示重启系统。

重启完成后，运行

```bash
bash bbr.sh start
```

启动魔改版BBR

## 查看魔改BBR状态
```bash
sysctl net.ipv4.tcp_available_congestion_control
```
如果看到有 **tsunami** 就表示开启成功！

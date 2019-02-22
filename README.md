## Mac 某信插件
感谢[@AloneMonkey/MonkeyDev](https://github.com/AloneMonkey/MonkeyDev)的框架支持，

感谢[@TKkk-iOSer/WeChatPlugin-MacOS](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS)的功能支持。

感谢[@lmk123/oh-my-wechat](https://github.com/lmk123/oh-my-wechat)的安装脚本功能支持。

<!--感谢[@Natoto/WeChatPlugin](https://github.com/Natoto/WeChatPlugin)的功能支持。-->

## 安装及卸载

首次安装，打开`应用程序-实用工具-Terminal(终端)`，执行下面的命令进行安装或更新：

```sh
curl -o- -L https://github.com/TozyZuo/WeChatPluginWrapperMac/raw/master/Other/OnlineInstall.sh | bash -s
```

插件安装完后会在每次启动自动检查更新，也可手动检查更新，如果开启自动更新，则无需用户确认，自动更新到最新版本。如果没有开启静默更新，则更新时，及更新完毕会发送通知，如果用户允许微信通知的话

卸载

```sh
curl -o- -L https://github.com/TozyZuo/WeChatPluginWrapperMac/raw/master/Other/Uninstall.sh | bash -s
```

## 目前已集成如下pod

### TKkk-WeChatPlugin（v1.7.5）
[详细功能请前往项目主页查看](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS)


<!--### Natoto-WeChatPlugin
功能：

* 朋友圈-->

### 添加功能
* 每条消息展示消息时间
* 语音自动转文字
* 插件自动更新

## License
MIT
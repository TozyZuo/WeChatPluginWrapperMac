#!/bin/bash

app_name="WeChat"
wechat_path="/Applications/${app_name}.app"

if [ ! -d "$wechat_path" ]; then
  wechat_path=${HOME}/Applications/WeChat.app
  if [ ! -d "$wechat_path" ]; then
    wechat_path="/Applications/微信.app"
    if [ ! -d "$wechat_path" ]; then
      wechat_path=${HOME}/Applications/微信.app
      if [ ! -d "$wechat_path" ]; then
        echo -e "\n\n未发现微信，请检查微信是否有重命名或者移动路径位置"
        exit
      fi
    fi
  fi
fi

version_file=${wechat_path}/Contents/MacOS/version


openwechat() {
  _isWeChatRunning=$(ps aux | grep [W]eChat.app | wc -l)
  if [ -n "$installed" ] && [ $_isWeChatRunning != "0" ]; then
    echo 检测到微信正在运行，请重启微信让插件生效。
  else
    echo 打开微信
    open $wechat_path
  fi
}

# 安装插件
install_version() {
  installed="y"
  _version=$1
  echo 开始下载插件 v${_version}……
  # 下载压缩包
  curl -L -o ${_version}.zip https://github.com/TozyZuo/WeChatPluginWrapperMac/archive/v${_version}.zip
  if [ 0 -eq $? ]; then
    # 解压为同名文件夹
    unzip -o -q ${_version}.zip
    # 删除压缩包
    rm ${_version}.zip
    echo 下载完成
  else
    echo 下载失败，请稍后重试。
    exit 1
  fi
  echo 开始安装插件……
  ./WeChatPluginWrapperMac-$_version/Other/Install.sh
  rm -rf ./WeChatPluginWrapperMac
  # 写入版本
  echo $_version >$version_file
  echo 插件安装完成。
  openwechat
}

# 获取当前版本
if [ -f $version_file ]; then
  current_version=$(cat $version_file)
  current_version=${current_version//$'\r'/}
  echo 当前插件版本为 v${current_version}
fi

if [ -z $latest_version ]; then
  echo 正在检查新版本……
  latest_version=$(curl -I -s https://github.com/TozyZuo/WeChatPluginWrapperMac/releases/latest | grep Location | sed -n 's/.*\/v\(.*\)/\1/p')
  if [ -z "$latest_version" ]; then
    echo 检查新版本时失败
  else
    latest_version=${latest_version//$'\r'/}
    echo 最新插件版本为 v${latest_version}
    if [ "$current_version" != $latest_version ]; then
      install_version $latest_version
    else
      echo 当前已是最新版本。
    fi
  fi
fi

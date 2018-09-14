#!/bin/bash

app_name="WeChat"
shell_path="$(dirname "$0")"
wechat_path="/Applications/WeChat.app"
app_bundle_path="/Applications/${app_name}.app/Contents/MacOS"
app_executable_path="${app_bundle_path}/${app_name}"
app_executable_backup_path="${app_executable_path}_backup"

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

# 对 WeChat 赋予权限
if [ ! -w "$wechat_path" ]
then
echo -e "\n\n为了将小助手写入微信, 请输入密码 ： "
sudo chown -R $(whoami) "$wechat_path"
fi

# 备份 WeChat 原始可执行文件
if [ ! -f "$app_executable_backup_path" ]
then
cp "$app_executable_path" "$app_executable_backup_path"
fi

# WeChatPluginWrapper
framework_name="WeChatPluginWrapper"
framework_path="${app_bundle_path}/${framework_name}.framework"
cp -r "${shell_path}/Products/Debug/${framework_name}.framework" ${app_bundle_path}
${shell_path}/insert_dylib --all-yes "${framework_path}/${framework_name}" "$app_executable_backup_path" "$app_executable_path"

# TK
framework_name="WeChatPlugin_TKkk"
framework_path="${app_bundle_path}/${framework_name}.framework"
cp -r "${shell_path}/Products/Debug/${framework_name}.framework" ${app_bundle_path}
${shell_path}/insert_dylib --all-yes "${framework_path}/${framework_name}" "$app_executable_backup_path" "$app_executable_path"

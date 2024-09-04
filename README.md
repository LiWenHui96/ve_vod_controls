# ve_vod_controls

[![pub package](https://img.shields.io/pub/v/ve_vod_controls)](https://pub.dev/packages/ve_vod_controls)
[![GitHub license](https://img.shields.io/github/license/LiWenHui96/ve_vod_controls?label=协议&style=flat-square)](https://github.com/LiWenHui96/ve_vod_controls/blob/master/LICENSE)

基于 [ve_vod](https://pub.dev/packages/ve_vod) 封装的视频播放器，携带控制器。

## 快速开始

### 准备工作

* [环境要求](https://www.volcengine.com/docs/4/1264515#%E7%8E%AF%E5%A2%83%E8%A6%81%E6%B1%82)
* [创建应用](https://www.volcengine.com/docs/4/79594)
* [License 包管理](https://www.volcengine.com/docs/4/65772)

### 添加依赖

将 `ve_vod_controls` 添加至 `pubspec.yaml` 引用

```yaml
dependencies:
  ve_vod_controls: ^latest_version

ve_vod:
  # 基础版
  sub_spec: standard
  # 高级版
  # sub_spec: premium
```

### 平台配置

#### Android

[环境要求](https://www.volcengine.com/docs/4/65774#%E7%8E%AF%E5%A2%83%E8%A6%81%E6%B1%82)

相关配置内容已在[本插件](#ve_vod_controls)以及 [ve_vod](https://pub.dev/packages/ve_vod) 中完成，无需重复配置。
包括：
1. 添加 maven 仓库
2. 添加 SDK 依赖
3. Java 8 支持
4. [权限声明](https://www.volcengine.com/docs/4/65774#%E6%9D%83%E9%99%90%E5%A3%B0%E6%98%8E)
5. [混淆规则](https://www.volcengine.com/docs/4/65774#%E6%B7%B7%E6%B7%86%E8%A7%84%E5%88%99)

> ⚠️ 特别注意：
> 
> WRITE_EXTERNAL_STORAGE 为非必需权限，可根据您的实际需求设置，插件内并未添加。

#### iOS

[环境要求](https://www.volcengine.com/docs/4/65775#%E7%8E%AF%E5%A2%83%E8%A6%81%E6%B1%82)

[ve_vod](https://pub.dev/packages/ve_vod) 中完成了SDK的集成，需要开发者自行添加相关配置：
1. [关闭 Bitcode](https://www.volcengine.com/docs/4/65775#%E5%85%B3%E9%97%AD%20Bitcode)
2. 配置 `Pod Source`。请在您的 Xcode 工程的 Podfile 文件中添加以下 Source：
```ruby
# 资源地址
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/volcengine/volcengine-specs.git'
```

### License 文件

推荐放置在 flutter 目录下 `assets/license/xxx.lic`

## 示例

### 引入头文件

```dart
import 'package:ve_vod_controls/ve_vod_controls.dart';
```

### 初始化SDK

```dart
VeVodControls.instance.init(
  appId: 'xx',
  licenseFilePath: 'assets/license/vod.lic',
  appName: 'xx',
  appVersion: '1.0.0',
  appChannel: 'dev',
);
```

## 火山云文档

* [功能详情](https://www.volcengine.com/docs/4/100095)
* [集成SDK](https://www.volcengine.com/docs/4/1264515)
* [功能使用](https://www.volcengine.com/docs/4/1264702)

> 如果你喜欢我的项目，请在项目右上角 "Star" 一下。你的支持是对我最大的鼓励！ ^_^
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ve_vod_controls.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 've_vod_controls'
  s.version          = '0.0.1'
  s.summary          = 'The Flutter plugin providers volcengine tt sdk native APIs to implement video player. 集成火山云视频点播原生SDK。'
  s.description      = <<-DESC
The Flutter plugin providers volcengine tt sdk native APIs to implement video player. 集成火山云视频点播原生SDK。
                       DESC
  s.homepage         = 'https://github.com/LiWenHui96'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'LiWeNHuI96' => 'sdgrlwh@163.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

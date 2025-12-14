#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint amplitude_experiments_flutter_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'amplitude_experiments_flutter_ios'
  s.version          = '0.0.1'
  s.summary          = 'iOS implementation of the amplitude_experiments_flutter plugin.'
  s.description      = <<-DESC
iOS implementation of the Amplitude Experiment SDK for Flutter
                       DESC
  s.homepage         = 'https://amplitude.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Amplitude' => 'dev@amplitude.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'AmplitudeExperiment', '~> 1.13'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {
    'amplitude_experiments_flutter_ios_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
end

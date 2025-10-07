Pod::Spec.new do |s|
  s.name = 'SharedContainerPlugin'
  s.version = '1.0.0'
  s.summary = 'Capacitor plugin for accessing iOS shared container'
  s.license = 'MIT'
  s.homepage = 'https://github.com/williamdphillips/capacitor-shared-container'
  s.author = 'Sounds Studios'
  s.source = { :git => 'https://github.com/williamdphillips/capacitor-shared-container', :tag => s.version.to_s }
  s.source_files = 'Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target  = '14.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
end


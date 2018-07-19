Pod::Spec.new do |s|
  s.name             = 'Bolts-Swift'
  s.version          = '1.4.0'
  s.license          =  { :type => 'BSD' }
  s.summary          = 'Bolts is a collection of low-level libraries designed to make developing mobile apps easier.'
  s.homepage         = 'https://github.com/BoltsFramework'
  s.authors          = { 'Nikita Lutsenko' => 'nlutsenko@me.com' }
  
  s.source       = { :git => 'https://github.com/BoltsFramework/Bolts-Swift.git', :tag => s.version.to_s }

  s.requires_arc = true

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  
  s.source_files = 'Sources/BoltsSwift/*.swift'
  s.module_name = 'BoltsSwift'
end

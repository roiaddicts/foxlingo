require 'xcodeproj'
root = File.expand_path('..', __dir__)
p = Xcodeproj::Project.new(File.join(root,'Foxlingo.xcodeproj'))
app = p.new_target(:application, 'Foxlingo', :ios, '17.0')
ui = p.new_target(:ui_test_bundle, 'FoxlingoUITests', :ios, '17.0')
ui.add_dependency(app)
app_group=p.main_group.new_group('Foxlingo','Foxlingo')
['Core','UI'].each do |dir|
 g=app_group.new_group(dir,dir)
 Dir.glob(File.join(root,'Foxlingo',dir,'*.swift')).sort.each {|file|app.add_file_references([g.new_file(File.basename(file))])}
end
resources=app_group.new_group('Resources','Resources')
['starter-en.json','games-en.json','Assets.xcassets'].each {|file|app.resources_build_phase.add_file_reference(resources.new_file(file))}
utg=p.main_group.new_group('FoxlingoUITests','FoxlingoUITests')
Dir.glob(File.join(root,'FoxlingoUITests','*.swift')).each {|file|ui.add_file_references([utg.new_file(File.basename(file))])}
[app,ui].each do |target|
 target.build_configurations.each do |c|
  c.build_settings['SWIFT_VERSION']='5.0'
  c.build_settings['GENERATE_INFOPLIST_FILE']='YES'
  c.build_settings['IPHONEOS_DEPLOYMENT_TARGET']='17.0'
  c.build_settings['TARGETED_DEVICE_FAMILY']='1'
  c.build_settings['CODE_SIGN_STYLE']='Automatic'
  c.build_settings['PRODUCT_BUNDLE_IDENTIFIER']=target == app ? 'com.diego.foxlingo' : 'com.diego.foxlingo.uitests'
  c.build_settings['SWIFT_EMIT_LOC_STRINGS']='YES'
  if target == app
   c.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation']='YES'
   c.build_settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation']='YES'
   c.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations']='UIInterfaceOrientationPortrait'
   c.build_settings['INFOPLIST_KEY_CFBundleDisplayName']='Foxlingo'
   c.build_settings['MARKETING_VERSION']='0.1.0'
   c.build_settings['CURRENT_PROJECT_VERSION']='1'
  else
   c.build_settings['TEST_TARGET_NAME']='Foxlingo'
  end
 end
end
p.save
scheme=Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(ui)
scheme.set_launch_target(app)
scheme.save_as(p.path,'Foxlingo',true)
puts 'Created Foxlingo.xcodeproj'

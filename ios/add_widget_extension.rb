#!/usr/bin/env ruby
# Script to add AttendanceWidget extension target to the Xcode project
# Run: cd ios && ruby add_widget_extension.rb

require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Check if target already exists
if project.targets.any? { |t| t.name == 'AttendanceWidget' }
  puts "AttendanceWidget target already exists. Skipping."
  exit 0
end

# Create the Widget Extension target
target = project.new_target(:app_extension, 'AttendanceWidget', :ios, '16.2')
target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.ppulse.hrmsDemo.AttendanceWidget'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['INFOPLIST_FILE'] = 'AttendanceWidget/Info.plist'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'AttendanceWidget/AttendanceWidget.entitlements'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  config.build_settings['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = 'WidgetBackground'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  config.build_settings['SKIP_INSTALL'] = 'YES'
end

# Add source files
group = project.new_group('AttendanceWidget', 'AttendanceWidget')

swift_files = [
  'AttendanceWidget/AttendanceWidgetBundle.swift',
  'AttendanceWidget/AttendanceActivityWidget.swift',
]

swift_files.each do |file_path|
  file_ref = group.new_file(file_path)
  target.source_build_phase.add_file_reference(file_ref)
end

# Add entitlements file reference
group.new_file('AttendanceWidget/AttendanceWidget.entitlements')

# Add Info.plist file reference
group.new_file('AttendanceWidget/Info.plist')

# Embed the extension in the main app
runner_target = project.targets.find { |t| t.name == 'Runner' }
if runner_target
  # Add embed extension build phase
  embed_phase = runner_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = '13' # PlugIns
  embed_phase.add_file_reference(target.product_reference, true)

  # Add Runner entitlements
  runner_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  end
end

project.save
puts "✅ AttendanceWidget target added successfully!"
puts "   Bundle ID: com.ppulse.hrmsDemo.AttendanceWidget"
puts "   Min iOS: 16.2"
puts "   App Group: group.com.ppulse.hrmsDemo"
puts ""
puts "Next steps in Xcode:"
puts "  1. Open Runner.xcworkspace"
puts "  2. Select AttendanceWidget target → Signing & Capabilities"
puts "  3. Set your Team for signing"
puts "  4. Add 'App Groups' capability → group.com.ppulse.hrmsDemo"
puts "  5. Do the same for Runner target (add App Groups)"

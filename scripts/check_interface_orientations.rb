#!/usr/bin/env ruby

# Verifies the orientation policy encoded in the app target's generated Info.plist settings.
# This deliberately inspects the project file rather than a built app so it can run without Xcode.

project_file = File.expand_path("../Mindsprout.xcodeproj/project.pbxproj", __dir__)
project = File.read(project_file)

configuration_blocks = project.scan(
  /[A-F0-9]+ \/\* (Debug|Release) \*\/ = \{\n\s*isa = XCBuildConfiguration;\n\s*buildSettings = \{\n(.*?)\n\s*\};\n\s*name = (?:Debug|Release);\n\s*\};/m
)

app_configurations = configuration_blocks.each_with_object([]) do |(configuration, settings), result|
  result << [configuration, settings] if settings.include?("PRODUCT_BUNDLE_IDENTIFIER = com.afp.Mindsprout;")
end

expected_settings = {
  "TARGETED_DEVICE_FAMILY" => '"1,2"',
  "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone" => "UIInterfaceOrientationPortrait",
  "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad" => "UIInterfaceOrientationPortrait",
  "INFOPLIST_KEY_UIRequiresFullScreen" => "YES"
}

abort "FAIL: expected two app configurations, found #{app_configurations.length}" unless app_configurations.length == 2

failures = app_configurations.flat_map do |configuration, settings|
  expected_settings.each_with_object([]) do |(key, value), result|
    line = settings.lines.find { |candidate| candidate.strip.start_with?("#{key} =") }
    result << "#{configuration}: expected #{key} = #{value}" unless line && line.include?("#{key} = #{value};")
  end
end

if failures.empty?
  puts "PASS: iPhone and iPad remain enabled; both are standard-portrait-only; iPad is full-screen-required."
else
  warn failures.join("\n")
  exit 1
end

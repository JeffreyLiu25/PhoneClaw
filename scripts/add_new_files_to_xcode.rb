#!/usr/bin/env ruby
# 这个脚本用于将新文件添加到 Xcode 项目中
# 注意：你需要安装 Xcodeproj gem：gem install xcodeproj

require 'xcodeproj'

project_path = 'PhoneClaw.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'PhoneClaw' }

group = project.main_group.find_subpath('Agent', true)
memory_group = group.new_group('Memory') unless group.find_subpath('Memory', true)

# 添加记忆系统文件
memory_files = [
  'Agent/Memory/UserProfile.swift',
  'Agent/Memory/LongTermMemory.swift',
  'Agent/Memory/MemoryTools.swift'
]

memory_files.each do |file_path|
  unless target.source_build_phase.files.find { |bf| bf.file_ref&.path == File.basename(file_path) }
    file_ref = memory_group.new_reference(file_path)
    target.add_file_references([file_ref])
    puts "Added: #{file_path}"
  end
end

# 添加网络工具
tools_group = project.main_group.find_subpath('Tools', true)
network_group = tools_group.new_group('Network') unless tools_group.find_subpath('Network', true)
doc_group = tools_group.new_group('Documentation') unless tools_group.find_subpath('Documentation', true)

network_files = [
  'Tools/Network/NetworkSettings.swift',
  'Tools/Network/NetworkClient.swift',
  'Tools/Network/GitHubTools.swift'
]

doc_files = [
  'Tools/Documentation/DocumentTools.swift'
]

network_files.each do |file_path|
  unless target.source_build_phase.files.find { |bf| bf.file_ref&.path == File.basename(file_path) }
    file_ref = network_group.new_reference(file_path)
    target.add_file_references([file_ref])
    puts "Added: #{file_path}"
  end
end

doc_files.each do |file_path|
  unless target.source_build_phase.files.find { |bf| bf.file_ref&.path == File.basename(file_path) }
    file_ref = doc_group.new_reference(file_path)
    target.add_file_references([file_ref])
    puts "Added: #{file_path}"
  end
end

project.save

puts "\n✅ Xcode project updated successfully!"
puts "You can now run git status to see the changes."

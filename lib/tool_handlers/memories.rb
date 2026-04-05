require 'fileutils'
require 'pathname'

module ToolHandlers
  class Memories
    DEFAULT_DIR = '/var/bot-bahamut/memories'
    MEMORIES_DIR = '/memories'
    MAX_LINES = 999_999

    def initialize(base_dir: nil)
      @base_dir = base_dir || ENV.fetch('MEMORIES_DIR', DEFAULT_DIR)
      FileUtils.mkdir_p(@base_dir)
    end

    def execute(input, scope_dir: nil)
      @effective_dir = scope_dir ? File.join(@base_dir, scope_dir) : @base_dir
      FileUtils.mkdir_p(@effective_dir)
      command = input['command']
      case command
      when 'view'
        view(input['path'], input['view_range'])
      when 'create'
        create(input['path'], input['file_text'])
      when 'str_replace'
        str_replace(input['path'], input['old_str'], input['new_str'])
      when 'insert'
        insert(input['path'], input['insert_line'], input['insert_text'])
      when 'delete'
        delete(input['path'])
      when 'rename'
        rename(input['old_path'], input['new_path'])
      else
        "Error: Unknown command '#{command}'"
      end
    end

    private

    # Convert a /memories/... path to the actual filesystem path
    # and validate against path traversal
    def resolve_path(virtual_path)
      return nil unless virtual_path

      # Strip the /memories prefix and join with base_dir
      relative = virtual_path.delete_prefix(MEMORIES_DIR)
      relative = relative.delete_prefix('/')
      actual = if relative.empty?
                 Pathname.new(@effective_dir)
               else
                 Pathname.new(@effective_dir).join(relative)
               end

      # Resolve to absolute path for traversal check
      # Use cleanpath first (doesn't require file to exist)
      cleaned = actual.cleanpath.to_s
      base_clean = Pathname.new(@effective_dir).cleanpath.to_s

      unless cleaned.start_with?(base_clean)
        return :traversal
      end

      cleaned
    end

    def check_path(virtual_path)
      resolved = resolve_path(virtual_path)
      if resolved == :traversal
        return nil, "Error: Access denied. Path must be within #{MEMORIES_DIR}."
      end
      [resolved, nil]
    end

    def view(path, view_range)
      resolved, error = check_path(path)
      return error if error

      unless File.exist?(resolved)
        return "The path #{path} does not exist. Please provide a valid path."
      end

      if File.directory?(resolved)
        view_directory(path, resolved)
      else
        view_file(path, resolved, view_range)
      end
    end

    def view_directory(virtual_path, resolved)
      entries = []
      collect_entries(resolved, virtual_path, entries, depth: 0, max_depth: 2)
      entries_text = entries.map { |size, entry_path| "#{size}\t#{entry_path}" }.join("\n")
      "Here're the files and directories up to 2 levels deep in #{virtual_path}, excluding hidden items and node_modules:\n#{entries_text}"
    end

    def collect_entries(dir, virtual_dir, entries, depth:, max_depth:)
      size = format_size(dir_size(dir))
      entries << [size, virtual_dir]

      return if depth >= max_depth

      Dir.children(dir).sort.each do |child|
        next if child.start_with?('.')
        next if child == 'node_modules'

        child_path = File.join(dir, child)
        child_virtual = "#{virtual_dir}/#{child}"

        if File.directory?(child_path)
          collect_entries(child_path, child_virtual, entries, depth: depth + 1, max_depth: max_depth)
        else
          size = format_size(File.size(child_path))
          entries << [size, child_virtual]
        end
      end
    end

    def dir_size(path)
      if File.file?(path)
        File.size(path)
      else
        Dir.glob(File.join(path, '**', '*')).sum { |f| File.file?(f) ? File.size(f) : 0 }
      end
    end

    def format_size(bytes)
      if bytes < 1024
        "#{bytes}"
      elsif bytes < 1024 * 1024
        format('%.1fK', bytes / 1024.0)
      else
        format('%.1fM', bytes / (1024.0 * 1024))
      end
    end

    def view_file(virtual_path, resolved, view_range)
      lines = File.readlines(resolved)

      if lines.size > MAX_LINES
        return "File #{virtual_path} exceeds maximum line limit of #{MAX_LINES} lines."
      end

      if view_range
        start_line = view_range[0]
        end_line = view_range[1]
        lines = lines[(start_line - 1)..(end_line - 1)] || []
        line_offset = start_line
      else
        line_offset = 1
      end

      numbered = lines.each_with_index.map do |line, i|
        line_num = line_offset + i
        format("%6d\t%s", line_num, line)
      end.join

      "Here's the content of #{virtual_path} with line numbers:\n#{numbered}"
    end

    def create(path, file_text)
      resolved, error = check_path(path)
      return error if error

      if File.exist?(resolved)
        return "Error: File #{path} already exists"
      end

      FileUtils.mkdir_p(File.dirname(resolved))
      File.write(resolved, file_text || '')
      "File created successfully at: #{path}"
    end

    def str_replace(path, old_str, new_str)
      resolved, error = check_path(path)
      return error if error

      unless File.exist?(resolved) && File.file?(resolved)
        return "Error: The path #{path} does not exist. Please provide a valid path."
      end

      content = File.read(resolved)
      occurrences = content.scan(old_str)

      if occurrences.empty?
        return "No replacement was performed, old_str `#{old_str}` did not appear verbatim in #{path}."
      end

      if occurrences.size > 1
        lines = content.lines
        line_numbers = []
        lines.each_with_index do |line, i|
          line_numbers << (i + 1) if line.include?(old_str)
        end
        return "No replacement was performed. Multiple occurrences of old_str `#{old_str}` in lines: #{line_numbers.join(', ')}. Please ensure it is unique"
      end

      new_content = content.sub(old_str, new_str)
      File.write(resolved, new_content)

      # Show snippet around the replacement
      new_lines = new_content.lines
      replaced_line_idx = new_lines.index { |l| l.include?(new_str) } || 0
      start_idx = [replaced_line_idx - 2, 0].max
      end_idx = [replaced_line_idx + 2, new_lines.size - 1].min
      snippet = (start_idx..end_idx).map { |i| format("%6d\t%s", i + 1, new_lines[i]) }.join

      "The memory file has been edited.\n#{snippet}"
    end

    def insert(path, insert_line, insert_text)
      resolved, error = check_path(path)
      return error if error

      unless File.exist?(resolved) && File.file?(resolved)
        return "Error: The path #{path} does not exist"
      end

      lines = File.readlines(resolved)
      n_lines = lines.size

      unless insert_line.is_a?(Integer) && insert_line >= 0 && insert_line <= n_lines
        return "Error: Invalid `insert_line` parameter: #{insert_line}. It should be within the range of lines of the file: [0, #{n_lines}]"
      end

      new_lines = insert_text.end_with?("\n") ? insert_text : "#{insert_text}\n"
      lines.insert(insert_line, new_lines)
      File.write(resolved, lines.join)

      "The file #{path} has been edited."
    end

    def delete(path)
      resolved, error = check_path(path)
      return error if error

      unless File.exist?(resolved)
        return "Error: The path #{path} does not exist"
      end

      FileUtils.rm_rf(resolved)
      "Successfully deleted #{path}"
    end

    def rename(old_path, new_path)
      old_resolved, error = check_path(old_path)
      return error if error

      new_resolved, error = check_path(new_path)
      return error if error

      unless File.exist?(old_resolved)
        return "Error: The path #{old_path} does not exist"
      end

      if File.exist?(new_resolved)
        return "Error: The destination #{new_path} already exists"
      end

      FileUtils.mkdir_p(File.dirname(new_resolved))
      FileUtils.mv(old_resolved, new_resolved)
      "Successfully renamed #{old_path} to #{new_path}"
    end
  end
end

require "tempfile"

module Eneroth
  module OpenNewerVersion
    module OpenNewer
      # Major version of the running SketchUp.
      SU_VERSION = Sketchup.version.to_i

      # Get SketchUp version string of a saved file.
      #
      # @param path [String]
      #
      # @raise [IOError]
      #
      # @return [String]
      def self.version(path)
        v = File.binread(path, 64).tr("\x00", "")[/{([\d.]+)}/n, 1]

        v || raise(IOError, "Can't determine SU version for '#{path}'. Is file a model?")
      end

      # Ask user for path to open from.
      #
      # @return [String]
      def self.prompt_source_path
        UI.openpanel("Open", "", "SketchUp Models|*.skp||")
      end

      # Ask user for path to save converted model to.
      #
      # @param source [String]
      #
      # @return [String]
      def self.prompt_target_path(source)
        # Prefixing version with 20 as SketchUp 2014 is the oldest supported
        # version. If ever supporting versions 8 or older, only prefix for
        # [20]13 and above.
        title = "Save As SketchUp 20#{SU_VERSION} Compatible"
        directory = File.dirname(source)
        filename = "#{File.basename(source, '.skp')} (SU 20#{SU_VERSION}).skp"

        UI.savepanel(title, directory, filename)
      end

      # Get platform-specific converter executable path.
      #
      # @return [String]
      def self.converter_path
        case Sketchup.platform
        when :platform_win
          File.join(PLUGIN_DIR, "bin", "ConvertVersion.exe")
        when :platform_osx
          File.join(PLUGIN_DIR, "bin", "ConvertVersion")
        else
          raise NotImplementedError, "Unsupported platform"
        end
      end

      # Ensure converter executable is present and runnable.
      #
      # @param path [String]
      #
      # @return [Boolean]
      def self.ensure_converter_available(path)
        unless File.exist?(path)
          UI.messagebox("#{EXTENSION.name} is missing its converter executable:\n#{path}")
          return false
        end

        if Sketchup.platform == :platform_osx && !File.executable?(path)
          File.chmod(0755, path)
        end

        true
      rescue SystemCallError => error
        UI.messagebox("#{EXTENSION.name} cannot run its converter executable:\n#{error.message}")
        false
      end

      # Get bundled framework/library search paths for the macOS converter.
      # The converter must use a SketchUpAPI.framework compatible with the
      # target macOS/SketchUp runtime.
      #
      # @return [Array<String>]
      def self.macos_framework_paths
        paths = [
          File.join(PLUGIN_DIR, "bin", "SU2026"),
          File.join(PLUGIN_DIR, "bin", "Frameworks")
        ]

        paths.select { |path| File.directory?(path) }.uniq
      end

      # Environment used to let the macOS converter find bundled frameworks.
      #
      # @return [Hash]
      def self.macos_system_environment
        paths = macos_framework_paths
        return {} if paths.empty?

        env = {}
        framework_paths = [ENV["DYLD_FRAMEWORK_PATH"]].compact + paths
        library_paths = [ENV["DYLD_LIBRARY_PATH"]].compact + paths
        env["DYLD_FRAMEWORK_PATH"] = framework_paths.reject { |path| path.empty? }.join(":")
        env["DYLD_LIBRARY_PATH"] = library_paths.reject { |path| path.empty? }.join(":")
        env
      end

      # Run converter without flashing command line window on Windows.
      #
      # @param source [String]
      # @param target [String]
      #
      # @return [Boolean]
      def self.system_call(source, target)
        path = converter_path
        return false unless ensure_converter_available(path)

        if Sketchup.platform == :platform_win
          cmd = %("#{path}" "#{source}" "#{target}" #{SU_VERSION})
          file = Tempfile.new(["cmd", ".vbs"])
          file.write("Set WshShell = CreateObject(\"WScript.Shell\")\n")
          file.write("WshShell.Run \"#{cmd.gsub('"', '""')}\", 0\n")
          file.close
          UI.openURL("file://#{file.path}")
          true
        elsif Sketchup.platform == :platform_osx
          system(macos_system_environment, path, source, target, SU_VERSION.to_s)
        else
          false
        end
      end

      # Run block once a file has been created.
      #
      # @param path [String]
      # @param async [Boolean]
      # @param delay [Flaot]
      # @param block [Proc]
      #
      # @return [Void]
      def self.on_exist(path, async = true, delay = 0.2, &block)
        if File.exist?(path)
          block.call
          return
        end

        if async
          UI.start_timer(delay) { on_exist(path, async, delay, &block) }
        else
          sleep(delay)
          on_exist(path, async, delay, &block)
        end

        nil
      end

      # Convert an external model to the current SU version and open it.
      #
      # @param source [String]
      # @param target [String]
      #
      # @return [Void]
      def self.convert_and_open(source, target)
        Sketchup.status_text = "Converting model to supported format..."

        # To avoid opening a stale file, make sure there is no existing file by
        # the same name before launching the converter.
        File.delete(target) if File.exist?(target)

        success = system_call(source, target)
        unless success
          Sketchup.status_text = ""
          UI.messagebox("#{EXTENSION.name} couldn't convert '#{File.basename(source)}'.")
          return nil
        end

        if Sketchup.platform == :platform_win
          on_exist(target, false) { Sketchup.open_file(target) }
        elsif File.exist?(target)
          Sketchup.open_file(target)
        else
          Sketchup.status_text = ""
          UI.messagebox("#{EXTENSION.name} couldn't convert '#{File.basename(source)}'.")
        end

        nil
      end

      # Ask for path to open, convert if needed and open.
      #
      # @return [Void]
      def self.open_newer_version
        source = prompt_source_path || return
        version = version(source).to_i
        if version <= SU_VERSION
          Sketchup.open_file(source)
          return
        end
        target = prompt_target_path(source) || return
        convert_and_open(source, target)

        nil
      end
    end
  end
end

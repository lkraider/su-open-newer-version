#-------------------------------------------------------------------------------
#
#    Author: Julia Christina Eneroth
# Copyright: Copyright (c) 2019
#   License: MIT
#
#-------------------------------------------------------------------------------

require "extensions.rb"

# Eneroth Extensions
module Eneroth

# Open Newer Version
module OpenNewerVersion

  path = __FILE__
  path.force_encoding("UTF-8") if path.respond_to?(:force_encoding)

  PLUGIN_ID = File.basename(path, ".*")
  PLUGIN_DIR = File.join(File.dirname(path), PLUGIN_ID)

  EXTENSION = SketchupExtension.new(
    "Eneroth Open Newer Version",
    File.join(PLUGIN_DIR, "main")
  )
  EXTENSION.creator     = "Julia Christina Eneroth"
  EXTENSION.description =
    "Convert and open models made in newer versions of SketchUp."
  version_path = File.join(PLUGIN_DIR, "version.rb")
  if File.exist?(version_path)
    load version_path
  end
  EXTENSION.version = defined?(VERSION) ? VERSION : "0.0.0-dev"
  EXTENSION.copyright   = "2022, #{EXTENSION.creator}"
  Sketchup.register_extension(EXTENSION, true)

end
end

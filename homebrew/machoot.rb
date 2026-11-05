cask "machoot" do
  version "0.1.1"
  sha256 :no_check

  url "https://github.com/metinyildirimnet/machoot/releases/download/v#{version}/Machoot.zip"
  name "Machoot"
  desc "Menu bar color picker that copies the color under the cursor"
  homepage "https://github.com/metinyildirimnet/machoot"

  depends_on macos: :sequoia

  app "Machoot.app"

  # The app is not notarized; remove the quarantine flag so it opens without a Gatekeeper prompt.
  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-dr", "com.apple.quarantine", "{{appdir}}/Machoot.app"],
        must_succeed:   false,
        writable_paths: ["Machoot.app"],
        writable_base:  :appdir
  end

  uninstall quit: "io.github.metinyildirimnet.Machoot"

  zap trash: "~/Library/Preferences/io.github.metinyildirimnet.Machoot.plist"
end

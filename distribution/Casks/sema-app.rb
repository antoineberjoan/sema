# Installe le DMG immuable de sema en conservant les contrôles de macOS.
cask "sema-app" do
  version "0.6.0"
  sha256 "a7e6abc3112a8fd40c7df2e043a3650c02e0ffd25d825bc33aee184d84da150b"

  url "https://github.com/antoineberjoan/homebrew-sema/releases/download/v#{version}/Sema-#{version}-arm64.dmg"
  name "sema"
  desc "Vos repères économiques Webstat sur Mac"
  homepage "https://getsema.app/"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Sema.app"
end

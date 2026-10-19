# Installe le DMG immuable de sema en conservant les contrôles de macOS.
cask "sema-app" do
  version "0.7.0"
  sha256 "b89dcc970ffa8f2c4df7c97de25684cae64748a23987855d5d236111d9dd4e4e"

  url "https://github.com/antoineberjoan/homebrew-sema/releases/download/v#{version}/Sema-#{version}-arm64.dmg"
  name "sema"
  desc "Vos repères économiques Webstat sur Mac"
  homepage "https://getsema.app/"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Sema.app"
end

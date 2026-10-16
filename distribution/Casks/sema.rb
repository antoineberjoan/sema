cask "sema" do
  version "0.4.0"
  sha256 "81c3c017f8a7356a71abaeaacb7f27b1a48f8b59d28651f2c6ac6fa3e2abe884"

  url "https://github.com/antoineberjoan/homebrew-sema/releases/download/v#{version}/Sema-#{version}-arm64.dmg"
  name "sema"
  desc "Vos repères économiques Webstat sur Mac"
  homepage "https://getsema.app/"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Sema.app"
end

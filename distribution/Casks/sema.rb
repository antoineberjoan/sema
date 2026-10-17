cask "sema" do
  version "0.5.0"
  sha256 "88ca20dc010b33f7132ed0e57902541a612ae7daca31c39c520d4c13e96b7f7d"

  url "https://github.com/antoineberjoan/homebrew-sema/releases/download/v#{version}/Sema-#{version}-arm64.dmg"
  name "sema"
  desc "Vos repères économiques Webstat sur Mac"
  homepage "https://getsema.app/"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Sema.app"
end

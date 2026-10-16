cask "sema" do
  version "0.2.0"
  sha256 "71660035ef0bcd16ef2006515989ef3ab7abec3b4c8c363576062bbc3016c96e"

  url "https://github.com/antoineberjoan/homebrew-sema/releases/download/v#{version}/Sema-#{version}-arm64.dmg"
  name "Sema"
  desc "Vos repères économiques Webstat sur Mac"
  homepage "https://sema.raregoat8192.chatgpt.site/"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Sema.app"
end

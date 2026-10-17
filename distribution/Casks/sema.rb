cask "sema" do
  version "0.5.1"
  sha256 "762e891f57f26db57c222f78c899e1d58bf432ef6b72a2623eda196bbf4c526d"

  url "https://github.com/antoineberjoan/homebrew-sema/releases/download/v#{version}/Sema-#{version}-arm64.dmg"
  name "sema"
  desc "Vos repères économiques Webstat sur Mac"
  homepage "https://getsema.app/"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Sema.app"
end

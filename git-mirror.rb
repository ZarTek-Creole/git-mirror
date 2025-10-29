# Homebrew formula for git-mirror
# Usage: brew install --build-from-source git-mirror.rb

class GitMirror < Formula
  desc "Clone or update all GitHub repositories for a user or organization"
  homepage "https://github.com/ZarTek-Creole/git-mirror"
  url "https://github.com/ZarTek-Creole/git-mirror/archive/v3.1.0.tar.gz"
  sha256 ""  # Will be calculated
  license "MIT"

  depends_on "bash" => "4.4"
  depends_on "git" => "2.25"
  depends_on "curl" => "7.68"
  depends_on "jq" => "1.6"
  depends_on "parallel"

  def install
    # Install main script
    bin.install "git-mirror.sh" => "git-mirror"
    
    # Install modules
    libexec.install Dir["lib/*"]
    
    # Install configuration files
    etc.install Dir["config/*"]
    
    # Install documentation
    doc.install "README.md", "LICENSE", "CONTRIBUTING.md", "CHANGELOG.md"
    
    # Install man page
    man1.install "docs/git-mirror.1.gz"
  end

  test do
    # Test help command
    assert_match "Usage:", shell_output("#{bin}/git-mirror --help")
    
    # Test version
    assert_match version.to_s, shell_output("#{bin}/git-mirror --help | grep -i version") || true
  end

  def caveats
    <<~EOS
      git-mirror has been installed!

      Basic usage:
        git-mirror users microsoft

      For more information:
        man git-mirror
        git-mirror --help

      Configuration files are located in:
        #{etc}

      For development:
        Check #{doc} for documentation
    EOS
  end
end


const core = require('@actions/core');
const fs = require('node:fs');
const cp = require('node:child_process');
const process = require('node:process');
const tc = require('@actions/tool-cache');
const os = require('os');
const path = require('path');

async function run(workingDirectory) {
  let ccRubies = cp.execSync('cibuildgem print_ruby_cc_version', { cwd: workingDirectory, encoding: 'utf-8' })

  await downloadRubies(ccRubies.split(':'))
  setupRakeCompilerConfig(workingDirectory)
}

async function downloadRubies(rubies) {
  for (const version of rubies) {
    let downloadUrl = getDownloadURL(version);
    let tarball = await tc.downloadTool(downloadUrl);

    if (isWindows()) {
      await tc.extract7z(tarball, `${rubiesPath()}/${version}`, '7z');
    } else {
      await tc.extractTar(tarball, `${rubiesPath()}/${version}`);
    }
  }
}

function setupRakeCompilerConfig(workingDirectory) {
  let rubiesRbConfig = fs.globSync(`${rubiesPath()}/*/*/lib/ruby/*/*/rbconfig.rb`)
  let currentRubyVersion = cp.execSync('ruby -v', { encoding: 'utf-8' }).match(/^ruby (\d\.\d\.\d)/)[1]
  let rbConfigPath = path.join(os.homedir(), ".rake-compiler", "config.yml")
  let rubyPlatform = cp.execSync('cibuildgem print_normalized_platform', { cwd: workingDirectory, encoding: 'utf-8' })

  fs.mkdirSync(`${os.homedir()}/.rake-compiler`)

  rubiesRbConfig.forEach((path) => {
    let rubyVersion = path.match(/rubies.(\d\.\d\.\d)/)[1]
    let rbConfigName = getRbConfigName(rubyPlatform, rubyVersion)

    if (rubyVersion != currentRubyVersion) {
      fs.writeFileSync(rbConfigPath, `${rbConfigName}: ${path}\n`, { flag: 'a+' })
    }
  })
}

function rubiesPath() {
  return path.join(process.env['RUNNER_TEMP'], 'rubies');
}

function getRbConfigName(rubyPlatform, rubyVersion) {
  return `rbconfig-${rubyPlatform}-${rubyVersion}`
}

function isDarwin() {
  return os.platform() == "darwin";
}

function isWindows() {
  return os.platform() == "win32";
}

function getDownloadURL(rubyVersion) {
  if (isWindows()) {
    return windowsInstallerURL(rubyVersion);
  } else {
    return rubyBuilderURL(rubyVersion);
  }
}

function rubyBuilderURL(rubyVersion) {
  let rubyReleasesUrl = 'https://github.com/ruby/ruby-builder/releases/download';
  let platform = os.platform();

  if (platform == "linux") {
    platform = "ubuntu-22.04"; // Not great but this is a quick workaround
  }

  return `${rubyReleasesUrl}/ruby-${rubyVersion}/ruby-${rubyVersion}-${platform}-${os.arch()}.tar.gz`;
}

function windowsInstallerURL(rubyVersion) {
  let rubyReleasesUrl = "https://github.com/oneclick/rubyinstaller2/releases/download"

  return `${rubyReleasesUrl}/RubyInstaller-${rubyVersion}-1/rubyinstaller-${rubyVersion}-1-${os.arch()}.7z`
}

module.exports = { run }

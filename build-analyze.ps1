$ErrorActionPreference = 'Stop'

# SonarQube needs a full clone to work correctly but some CIs perform shallow clones
# so we first need to make sure that the source repository is complete
git fetch --unshallow

$SONAR_SERVER_URL = "$env:SONAR_HOST_URL" # Url to your SonarQube instance. In this example, it is defined in the environement through a Github secret.
#$SONAR_TOKEN = # Access token coming from SonarQube projet creation page. In this example, it is defined in the environement through a Github secret.
$SONAR_SCANNER_VERSION = "4.8.0.2856" # Find the latest version in the "Windows" link on this page:
                                      # https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/
$BUILD_WRAPPER_OUT_DIR = "bw-output" # Directory where build-wrapper output will be placed

mkdir $HOME/.sonar

# Prepare downloading and extraction of build-wrapper and sonar-scanner
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Download build-wrapper
$path = "$HOME/.sonar/build-wrapper-win-x86.zip"
(New-Object System.Net.WebClient).DownloadFile("$SONAR_SERVER_URL/static/cpp/build-wrapper-win-x86.zip", $path)
[System.IO.Compression.ZipFile]::ExtractToDirectory($path, "$HOME/.sonar")
$env:Path += ";$HOME/.sonar/build-wrapper-win-x86"

# Download sonar-scanner
$path = "$HOME/.sonar/sonar-scanner-cli-$SONAR_SCANNER_VERSION-windows.zip"
(New-Object System.Net.WebClient).DownloadFile("https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_SCANNER_VERSION-windows.zip", $path)
[System.IO.Compression.ZipFile]::ExtractToDirectory($path, "$HOME/.sonar")
$env:Path += ";$HOME/.sonar/sonar-scanner-$SONAR_SCANNER_VERSION-windows/bin"

# Build inside the build-wrapper
build-wrapper-win-x86-64 --out-dir $BUILD_WRAPPER_OUT_DIR msbuild sonar_scanner_example.vcxproj /t:rebuild /nodeReuse:false

# Run sonar scanner
sonar-scanner.bat --define sonar.host.url=$SONAR_SERVER_URL --define sonar.login=$SONAR_TOKEN --define sonar.cfamily.build-wrapper-output=$BUILD_WRAPPER_OUT_DIR

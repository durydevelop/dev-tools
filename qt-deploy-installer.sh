mkdir -p DistributionKit/Installer
"$cqtdeployer" -bin $1 -targetDir DistributionKit/Installer qif
# TODO: -customScript
# TODO: -qifTheme
#cd DistributionKit
#ldd-cp-missed.sh $1
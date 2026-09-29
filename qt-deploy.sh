#mkdir -p "$(pwd)/DistributionKit/App"
#echo $(pwd)/DistributionKit/App
"$cqtdeployer" -bin $1 -targetDir ./DistributionKit/App
cd DistributionKit/App
ldd-cp-missed.sh $1

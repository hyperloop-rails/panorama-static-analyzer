app=$1
input=$2
output='./applications/'
pre_pro='./preprocess_views'
controller='./controller_model_analysis'
call=$input/'calls.txt'
schema=$input/db/'schema.rb'
rm -rf $output/$app
echo "remove existing"
mkdir $output/$app
echo "move app dir to applications "
cp -r $input/app/* $output/$app/
cp $call $output/$app
cp $schema $output/$app
echo "finished moving"

echo "preprocessing"
echo $app
cd $pre_pro; pwd; ruby main.rb -a $app; cd ../
echo "finish preprocessing"

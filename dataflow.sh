app=$1
output='./applications/'
pre_pro='./preprocess_views'
controller='./controller_model_analysis'

echo "jruby get dataflow"
cd $output; pwd; ruby generate_dataflow_log.rb $app;  cd ../
echo "FINISH dataflow"

#echo "run analysis"
#cd $controller; pwd; ruby main.rb -p $c_a -d ../$output/$app/ 
#echo "FINISH analysis"

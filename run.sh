#apps=(discourse fulcrum openstreetmap ror tracks)
apps=(onebody openstreetmap)
for i in "${apps[@]}"
do 
 rm -rf applications/pw-$i
 ./analyze.sh pw-$i /Users/jwy/Research/apps/$i/    
done

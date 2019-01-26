apps=(lobsters redmine spree diaspora falling-fruit onebody openstreetmap discourse fulcrum openstreetmap ror tracks)
for i in "${apps[@]}"
do 
  ruby main.rb -a -d ../applications/pw-$i > ../applications/pw-$i/choices.log
done

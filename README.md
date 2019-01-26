Below are steps to run Panorama to analyze and improve your own Rails application.

### Modify your app
Since Panorama changes the webpage layout and monitors then code change, you need to modify your app to enable such functionality.

* Add the following to your Gemfile
```
gem 'will_paginate'
gem 'bootstrap-sass'
gem 'sass-rails'
gem 'render_async'
gem 'react-rails-hot-loader'
gem 'active_record_query_trace'
```
You can also do this by
```
cd panorama-static-analyzer
ruby add_gems.rb path-to-app/
```

* Add the following to `app/assets/javascripts/application.js` or `app/assets/javascripts/application.js.erb` (if such files exist, otherwise create the file):
```
//= require bootstrap-sprockets
//= require react-rails-hot-loader  
//= require_tree ./interact
```

* Create a folder `interact/`:
```
$ mkdir app/assets/javascripts/interact
```

* Add the following to `app/assets/stylesheets/application.scss` (create this file if not exists):
```
@import "bootstrap-sprockets";
@import "bootstrap";
```

* Create new `active_query_trace.rb`:
```
$ touch config/initializer/active_query_trace.rb
```
and add the following to this file:
```
ActiveRecordQueryTrace.enabled = true
ActiveRecordQueryTrace.lines = 0
ActiveRecordQueryTrace.level = :rails
``` 

* Add the following to the body of your view file (e.g., `app/views/layouts/application.html.erb`):
```
<%= content_for :render_async %>
```
For instance,<br/>
<img src="https://hyperloop-rails.github.io/panorama/screenshots/contentfor.png" width="200"><br/>

* Add the following to the head of your application_controller.rb:
```
require 'will_paginate/array'
```
For instance,<br/>
<img src="https://hyperloop-rails.github.io/panorama/screenshots/application_controller.png"><br/>

* create `calls.txt`<br/>
The tool needs to know all entrance controller actions from your application. It assumes them to be stored in a file called `calls.txt`. You can generate that file by running:
  ```
  $rake routes | tail -n +2 | awk '{ for (i=1;i<=NF;i++) if (match($i, /.#./)) print $i}' | sed -e 's/#/,/g' | sort | uniq
  ```
  in your app, and then copying it to `<APPDIR>/calls.txt`.

### Download Panorama and install related packages
* Clone the [Panorama source code](https://github.com/hyperloop-rails) from github.

* The following packages need to be installed in order to run Panorama:
```
$ gem install yard
$ gem install activesupport
$ gem install work_queue
```

### Use Panorama for your app
* First run the application server and generate the log file that records the queries issued when visiting pages (i.e., `./log/development.log`).

* Update PATH environment:
```
$ export PATH=$PATH:path-to-panorama/compiled-jruby/bin
```

* Generate dataflow files:
```
cd path-to-panorama/
./perf_action.sh  app-name path-to-app/
```
`./perf_action.sh` takes two parameters, the first is the application name, which is used to create a folder to store dataflow information; the second is the path to the application souce code.

* Monitor an action in your app:
```
cd path-to-panorama/controller_model_analysis/
./compute_performance.sh app-name path-to-app/ controller-action
```
`./compute_performance.sh` takes three parameters. The third `controller-action` is the name of the action that you want to monitor, for instance, `BlogsController,index`.

* Start the app server, and visit the corresponding webpage (i.e., the page generated from the action you wish to monitor).
You will see the page with heatmap showing the cost of each element:<br/>
![heatmap](https://hyperloop-rails.github.io/panorama/screenshots/heatmap.png)<br/>

* When you move the cursor to an element and click, it will show patches that Panorama can generate to accelerate the element:<br/>
<img src="https://hyperloop-rails.github.io/panorama/screenshots/choices2.png" width="300"><br/>
When you click the patch (e.g., pagination), the patch will be automatically added to your source code.<br/>
Then you can refresh the page and see the new webpage:
![newpage](https://hyperloop-rails.github.io/panorama/screenshots/newpage.png)<br/>


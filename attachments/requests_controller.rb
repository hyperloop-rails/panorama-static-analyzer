 class RequestsController < ApplicationController
  def request_handle   
      f = open("request.log", 'w+')
      f.write(params[:data_value])
      f.close
      #render :nothing => true, :status => 200, :content_type => 'text/html'
      # wait for the code refactor 
      # when refactor is finished, it should put "OK" in the request.log
      while true
        con = open('request.log').read
      	if con.include?("FINISH")
      		f = open("request.log", 'w')
          f.write("")
          f.close
          if con.include?('NO')
            respond_to do |format|
              format.js {render inline: "alert('You did not accept the code change');" }
            end
          else
            respond_to do |format|
              format.js {render inline: "location.reload();" }
            end
          end
      		break
      	end
      	sleep(0.5)
      end
   end
end
Link to the app: https://salon-inventory-tracker.herokuapp.com/signin

Salon Inventory is a web application designed to make it easier for hair dressers to manage their supply of hair color products. The application is a ruby web app built using the Sinatra web development framework. It employs ERB as the templating language for dynamically generating HTML pages. User data is persisted using PostgreSQL. Passwords are secured using bcrypt, and user input is sanatized throughout the site to protect against cross-site scripting. A comprehensive test suite is provided which uses Rack's built-in testing library.

*Please Note* 
Although I have attempted to employ certain security features, please do not use a real username and password that you would be worried about sharing with the world. This application is a project for me to learn with, and does not employ all of the security features that are necessary in a fully secured application.  

Some things to be aware of:
1. If you are not familiar with hair products it may be helpful to know that hair colors employ a special classification system comprised of two numbers seperated by a "/". The first number is the "Depth" of the color, and is an integer from 1 up to 11. The second number is the "Tone" of the color, and is composed of a digit representing the major tone, with an optional second digit representing the minor tone. Both digits range from 0 to 9, with the second digit being a subdivision of the first digit. Thus, "11" would come after "1", but before "2". The complete color number will look like this: "3/5", where "3" is the depth and "5" is the tone. 

2. The "color line" is the brand which produces the color product. 


Thank you for checking out my app! I hope you enjoy your visit. 

Zach Morgan - Developer



Notes for developers:
If you pull down the code to your local machine, you must setup the database yourself. This can be done easily by `cd`ing into the `/data` directory, and running `ruby db_setup.rb`. As long as you have PostgreSQL installed on your machine, this (along with `bundle install`) should be all you need to run the app locally. 
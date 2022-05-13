Link to the app: https://salon-inventory-tracker.herokuapp.com/signin

If you want to check out the app without having a setup a new account, feel free to login using this demo account:

username: johngalt 
pasword: whoisjohngalt

Salon Inventory is a web application designed to make it easier for hair dressers to manage their supply of hair color products. The application is a ruby web app built using the Sinatra web development framework. It employs ERB as the templating language for dynamically generating HTML pages using ruby code on the back-end. Passwords are secured using a bcrypt algorithm, and user input is sanatized throughout the site to protect against cross-site scripting. A comprehensive test suite is provided which uses Rack's built-in testing library.

*Please Note* 
Although I have attempted to employ certain security features, please do not use a real username and password that you would be worried about sharing with the world. This application is a project for me to learn with, and does not employ all of the security features that are necessary in a fully secured application. 

Because this app is deployed on Heroku, any account that is created may not persist after a few hours. I plan to release an updated version of this app in the future which will include database functionality to persist user information over time. 

Some things to be aware of:
1. If you are not familiar with hair products it may be helpful to know that hair colors employ a special classification system comprised of two numbers seperated by a "/". The first number is the "Depth" of the color, and is an integer from 1 up to 11. The second number is the "Tone" of the color, and is composed of a digit representing the major tone, with an optional second digit representing the minor tone. Both digits range from 0 to 9, with the second digit being a subdivision of the first digit. Thus, "11" would come after "1", but before "2". The complete color number will look like this: "3/5", where "3" is the depth and "5" is the tone. 

2. The "color line" is the brand which produces the color product. 


Thank you for checking out my app! I hope you enjoy your visit. 

Zach Morgan - Developer

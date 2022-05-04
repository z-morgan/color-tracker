Goals for this app:

Inventory will be a place to keep track of all of the products (mainly hair color) that Moriah has in stock. 

Requirements:
- store in-stock products
- display in-stock products with their quantities
- add new products that have been ordered
- remove products as they are used up (opened)
- allow non-users to login, but require sign-in for any additions or edits

Extra: 
- deploy this app in a web-accessible way
  - employ a data-persisting tool such as S3 to store data over time
- have a page which displays a history of all additions and edits to the inventory
- feature a tool to calculate how much product should be ordered for the next month.

nouns:
  Inventory
  Product
  Color < Product
  User/account

verbs:
  display inventory
  add products
  use/delete products
  make account
  sign in
  sign out

  Steps:
  - create a homepage
  - create a way to retreive and dispay data from a yaml file


  Next steps:
  - add more criteria for an acceptable password when registering.
    - at least 8 characters long
    - contains two of the following: uppercase letter, digit, special character.
    
  - add the ability to handle multiple pages of colors in a line
  - add the ability to handle multiple pages of color lines
    - put navigation bottons at the bottom of the inventory-backing box, in place of the add-items form. 
    - create a page class to handle the contents of each page? Not sure yet...


notes:
- B/c using testing environment when testing, not testing bcrypt password creation or authentication.

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
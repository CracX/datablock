<p align="center">
  <img width="150" height="150" src="https://github.com/CracX/datablock/blob/master/readme/logo.png?raw=true">
</p>
<h2 align="center">DataBlock - Easy-to-use database framework running in Minecraft</h3>
<hr>

![GitHub repo size](https://img.shields.io/github/repo-size/CracX/datablock?label=Size)
![Latest Release](https://badgen.net/badge/Latest%20release/In%20Development/yellow?icon=github)

<h1 align="center">🔎 What is DataBlockDB?</h1>
DataBlock is a database management framework written purely in Lua and compatitable with CCTweaked mod. CCTweaked is a fork of a ComputerCraft mod and gives players the ability to work with computers in Minecraft.

While playing around with this mod, I wanted to create a Bank system for players to be able to transact digital money in-game. However, this meant that I would somehow need to manage players money and save their account status without using some 3rd party plugins. This is where the idea of a database framework in minecraft came from.

DBDB (DataBlockDB) works with saving all the data in a comma separated fasion in any file. Think of .csv files. This pretty much IS a glorified csv file parser.

![](https://raw.githubusercontent.com/deepriverproject/datablock/master/readme/get_row.gif)
<sub><sup>Note: The bug with the headers being reversed has been fixed after I made this gif. Been lazy to update it.</sup></sub>

<h1 align="center">🛠️ Setup</h1>
Go into your Minecraft world, open up your CC computer, and create a directory:

```lua
mkdir mydir
```
Go into your directory: 

```lua
cd mydir
```
Download the latest library file:

```lua
wget https://raw.githubusercontent.com/deepriverproject/datablock/master/datablockdb.lua
```
Now that you have the library file, you can import it into your Lua files by adding this to the top of them:
```lua
require "datablockdb"
```
Before you start managing your database, you need to first create the database file. For example `database.txt`

In this file, you need to define the headers before you can do any kind of operation. Headers are like lables for each column of the table.
Lets do an example and put this in our `database.txt` file:
```lua
id,first_name,last_name,money
```
Now that we have everything ready, all that is left to do is to create a `DataBlockDB` object. Go into your Lua file and after you imported the library, do:
```lua
db = DataBlockDB:new(nil, "/mydir/database.txt")
```
Do note that the second parameter NEEDS to be an absolute path to your database file.

<h1 align="center">📓 Usage</h1>

To create a library object:
```lua
DataBlockDB:new(nil, database_file_path)
```
To load in the database file (is done automatically):
```lua
DataBlockDB:parse_db()
```
To save the loaded database table into the database file (is done automatically):
```lua
DataBlockDB:dump_db()
```
To get a row by a header value:
```lua
DataBlockDB:find_row_by_header(header, header_value)
```
To find multiple rows by a header value:
```lua
DataBlockDB:find_rows_by_header(header, header_value)
```
To delete a row by a header value:
```lua
DataBlockDB:delete_row_by_header(header, header_value)
```
To update a row by a header value:
```lua
DataBlockDB:delete_row_by_header(find_header, find_value, update_header, update_value)
```
To insert new data:
```lua
DataBlockDB:insert(data)
```

<h1 align="center">⚠️ Limitations</h1>

- DBDB cannot guess what datatype is in every column, so it defaults every value type to be string.
- When inserting data, you cannot use commas (,) as part of the value due to how CSV parsing works.
- DBDB cannot manage more than one database per instance, but this can be overcome by using multiple DBDB objects for each database file.
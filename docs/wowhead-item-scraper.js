// First, for reference, The core scraping tha gets at the item id (modified below to use ini a sql query)
$('.listview-scroller').find('tbody.clickable tr').find('a.q4').map(function(i,v){return $(v).prop('href')}) 

// The script, broken down:
// 1. Get boss id
var bossid = /npc=([0-9]+)\//g.exec(window.location.pathname).pop(); 
// 2. Get avatar image for boss info
var bossinfo = $('div.infobox-portrait img');
// 3. Extract name (alt text of img) and img url and convert into sql insert
var sql = "insert into bosses (id, name, avatar_url) values\n("+bossid+',"'+bossinfo.prop('alt')+"\",'"+bossinfo.prop('src')+"')\n;\n\n"

// Use the main extractor and prev. boss id to throw together the insert for all items
sql += "INSERT INTO items (boss_id, item_id) values \n" + $('.listview-scroller').find('tbody.clickable tr').find('a.q4').map(function(i,v){return "("+bossid+","+(/item=([0-9]+)&/g.exec($(v).prop('href'))[1])+")"}).toArray().join(',\n')+"\n;"

// Next we throw it all into one big line for copy/paste into query browser

//
// THE ACTUAL SCRIPT TO EXECUTE!! 
//
var bossid = /npc=([0-9]+)\//g.exec(window.location.pathname).pop(); var bossinfo = $('div.infobox-portrait img');var sql =  "insert into bosses (id, name, avatar_url) values\n("+bossid+',"'+bossinfo.prop('alt')+"\",'"+bossinfo.prop('src')+"')\n;\n\n";sql += "INSERT INTO items (boss_id, item_id) values \n" + $('.listview-scroller').find('tbody.clickable tr').find('a.q4').map(function(i,v){return "("+bossid+","+(/item=([0-9]+)&/g.exec($(v).prop('href'))[1])+")"}).toArray().join(',\n')+"\n;"

// SUPER IMPORTANT NOTICE!!!
// We're just throwing quotes around strings into a sql query and assuming that should be that.  Super bad practice and every query should be looked over / fixed up before running it. An improvement to this would be to make an input cleaner and wrap all inputs w/ them
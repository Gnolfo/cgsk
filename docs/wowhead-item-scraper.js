// First, for reference, The core scraping that gets at the items
$('.listview-scroller').find('tbody.clickable tr').find('a.q4').map(function(i,v){return $(v).prop('href')}) 

// And a mapping of item type to list:
var item_list_map = 
	{	'2.15': 3,'4.4': 1, '4.-3': 4, '2.3':3, '4.1': 1, '4.-4': 3,'4.-6':4,'4.2':1,'4.3':1,'4.-2':4, 
		'4.6':4,'2.4':3, '15.-2':2, '2.0':3,'2.6':3,'2.10':3,'2.7':3,'2.8':3,'4.-5':4,'2.19':3,'2.18':3,
		'2.5':3,'2.1':3,'2.13':3,'2.2':3};

// The script, broken down:
// 1. Get boss id
var bossid = /npc=([0-9]+)\//g.exec(window.location.pathname).pop(); 
// 2. Get avatar image for boss info
var bossinfo = $('div.infobox-portrait img');
// 3. Extract name (alt text of img) and img url and convert into sql insert
var sql = "insert into bosses (id, name, avatar_url) values\n("+bossid+',"'+bossinfo.prop('alt')+"\",'"+bossinfo.prop('src')+"')\n;\n\n"

// 4. Get array of item info
var items = $('.listview-scroller').find('tbody.clickable tr').find('a.q4').parent().parent().parent()

// 5. Parse that shit... It's complicated, see the stuff at the bottom if interested

//
// THE ACTUAL SCRIPT TO EXECUTE!! 
//
var item_list_map = {'2.15': 3,'4.4': 1, '4.-3': 4, '2.3':3, '4.1': 1, '4.-4': 3,'4.-6':4,'4.2':1,'4.3':1,'4.-2':4, '4.6':4,'2.4':3, '15.-2':2, '2.0':3,'2.6':3,'2.10':3,'2.7':3,'2.8':3,'4.-5':4,'2.19':3,'2.18':3,'2.5':3,'2.1':3,'2.13':3,'2.2':3};var bossid = /npc=([0-9]+)\//g.exec(window.location.pathname).pop(); var bossinfo = $('div.infobox-portrait img');var sql =  "insert into bosses (id, name, avatar_url) values\n("+bossid+',"'+bossinfo.prop('alt')+"\",'"+bossinfo.prop('src')+"')\n;\n\n";sql += "INSERT INTO items (boss_id, item_id, list_id) values \n" + $('.listview-scroller').find('tbody.clickable tr').find('a.q4.listview-cleartext').map(function(i,v){var type = /items=(.+)/g.exec($(v).parent().parent().parent().find('td.q1 a').prop('href'))[1]; var ti = $(v).parent().parent().parent().find('td a.tinyspecial'); return {id:(/item=([0-9]+)&?/g.exec($(v).prop('href'))[1]),  type: type, type_eng: $(v).parent().parent().parent().find('td.q1 a').html(), ti: (ti.length > 0 ? /item=([0-9]+)&?/g.exec($(ti).prop('href'))[1] : null) }}).toArray().reduce(function(p,c){var id =c.ti?c.ti:c.id; if(!p.items[id]){p.items[id] = true; p.sql.push({id:id,type:(c.ti?'15.-2':c.type),type_eng:c.type_eng});} return p},{items:[],sql:[]}).sql.map(function(v){var type = (item_list_map[v.type] ? item_list_map[v.type] : v.type+' '+v.type_eng); return "("+bossid+","+v.id+","+type+")"}).join(',\n')+"\n;"

// Usage should be simple: go to a boss page on wowhead (make sure "drops" tab is open) and copy/paste the above oneliner into the js console. 
// You should see a pair of sql queries outputted to the console.  If not just do "console.log(sql)" as a followup.  Chrome should do this automatically.
// Either way those queries should be ready to go for table insertion.  IF however you see a list_id for an item that isn't just a number, it means the item_list_map needs to be updated (see below for more)
// ANOTHER SUPER IMPORTANT NOTICE!!!
// We're just throwing quotes around strings into a sql query and assuming that should be that.  Super bad practice and every query should be looked over / fixed up before running it. 
// An improvement to this would be to make an input cleaner and wrap all inputs w/ them.  But i'm lazy

 
// If you're super curious, here is that sucker with a little more whitespace and a few comments
var item_list_map = 
	{	'2.15': 3,'4.4': 1, '4.-3': 4, '2.3':3, '4.1': 1, '4.-4': 3,'4.-6':4,'4.2':1,'4.3':1,'4.-2':4, 
		'4.6':4,'2.4':3, '15.-2':2, '2.0':3,'2.6':3,'2.10':3,'2.7':3,'2.8':3,'4.-5':4,'2.19':3,'2.18':3,
		'2.5':3,'2.1':3,'2.13':3,'2.2':3};

var bossid = /npc=([0-9]+)\//g.exec(window.location.pathname).pop(); 

var bossinfo = $('div.infobox-portrait img');

var sql =  "insert into bosses (id, name, avatar_url) values\n("+bossid+',"'+bossinfo.prop('alt')+"\",'"+bossinfo.prop('src')+"')\n;\n\n";

sql += "INSERT INTO items (boss_id, item_id, list_id) values \n" + // simple start of the query string
	$('.listview-scroller').find('tbody.clickable tr').find('a.q4.listview-cleartext') // grab our items in jquery
	.map(function(i,v){
		var type = /items=(.+)/g.exec($(v).parent().parent().parent().find('td.q1 a').prop('href'))[1]; // items have types like "4.-6" is a shield I think, they should all map to list ids in item_list_map
		var ti = $(v).parent().parent().parent().find('td a.tinyspecial');  // "tier item" basically detect the tier item id out of the row so we know it's tier (special treatment)
		return {id:(/item=([0-9]+)&?/g.exec($(v).prop('href'))[1]),  // parsed item id
			type: type, // already parsed above, it's the wowhead code like 2.18, 2.5, etc
			type_eng: $(v).parent().parent().parent().find('td.q1 a').html(), // "type english" this is for debugging, it will say something like "Amulet" so we can add it to the mapping if we see it
			ti: (ti.length > 0 ? /item=([0-9]+)&?/g.exec($(ti).prop('href'))[1] : null) }}) // item # for tier token, or else null
	.toArray() // coersion from jquery obj to array
	.reduce(function(p,c){var id =c.ti?c.ti:c.id; // Note we are using the tier token id if it exists, otherwise the item's id
		if(!p.items[id]){ // only inserting if we haven't seen this item before
			p.items[id] = true; 
			p.sql.push({id:id,type:(c.ti?'15.-2':c.type),type_eng:c.type_eng}); // 15.-2 is the tier token item id, had to hardcode unfortunately
			}
		 return p
		},{items:[],sql:[]}) // note: items is to track what we've processed so we don't duplicate (mainly for tier), and sql is what data gets used after this...
	.sql
	.map(function(v){var type = (item_list_map[v.type] ? item_list_map[v.type] : v.type+' '+v.type_eng); // NOTE! If you see a list id like "2.2 Bow" then it needs to get added to the item_list_map it's not valid SQL!
		return "("+bossid+","+v.id+","+type+")"}).join(',\n')+"\n;" // The actual sql values for each item we're inserting
<h1>HUDU <---- Unifi Documentation Script</h1><br>
Since HUDU lacks a flexible/dynamic asset right now this does require a static template created there, i've included a template creation script but i would recommend hand creating the templates if you have any assets stored right now, or modifying the unifi-master script with the correct field names and template names where you want the data, i haven't tested the CREATE script at all, but theoretically it should work.<br>

The sync script WILL FAIL if any field names or types are different then the template specifies.<br><br>

<b>TO DO:<br></b>

[X] Compare existing assets with info in script and only update if different.<br>
[X] Shrink number of hits to IP Info by checking if info is needed before doing update<br>
[X]ish Correct GetAssets to be faster, new update by HUDU allows the Asset pulls to be as long as you want.  Speeds it up quite a bit to go from 25 per GET to 500 per GET (not API limited), still plan to use filtered Asset pulls once those are available.<br>
[] More documentation?<br>
[] Port map for switches... this is a moon shot but i'll think of something... any ideas are appreciated. <br><br>

<i>GetAssets is the slowest aspect of the script right now, on average it takes about 1-20 seconds (depending on number of assets, some of my hudu companies have over 1000 assets, i document way too much....) for each call, with 50-60 sites in Unifi that adds up to over 10 minutes per sync... really inefficient, so far HUDU doesn't allow filtering of assets or setting pagination numbers so each 25 assets require one request, slows the UI to a crawl while it's running and takes forever right now, Dev team has told me thats on the short list at the moment (both things pagination and filtered results), but we'll see when it's around..</i><br>

Any ideas from the community on changes or additional info I should work into the documentation script would be welcome... send it over as an issue on the script.


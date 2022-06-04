# Powershell Webapp for localhost
This lil collection of files brings the rich gui capabilities of the Web to your local scripts. (Not just powershell scripts tho ...).
It is the perfect replacement for HTA applications:
- The rich UI talks to the Powershell server
- The Powershell Server runs all System commands and responds to the UI

You just have to add more UI to the static folder and extend the Endpoints in the Powershell script to your own needs.
For correct Local-App-Behavior, every page on your Webapp has to run the */static/base.js* on load.
-> just add <script src="/static/base.js"></script> on top of your html pages.

*The flow for the enduser:*
- Run the ./run batch file
- ./run starts a powershell-script wich starts a webserver on localhost and ...
- ... points the default browser to the desired start location on the webserver
- If no html page of the webapp is open, the server shuts down after short time
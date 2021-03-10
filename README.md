# d20b11b7-ef81-420f-8c81-8eaf5e3a19c2

This script creates VM with a specific label and does the automatic shutdown of that VM at 18:00 CET
and automatic start at 8:00 CET.

To run the script:
1. Clone this repository (obviously)
1. Create new project under: https://console.cloud.google.com/projectcreate
1. Create service account for the newly created project, here: https://console.cloud.google.com/apis/credentials/serviceaccountkey
   (Pssst: I used 'owner' role to simplify things as this is PoC only)
1. from the above account creation, download file in JSON format
1. Save the downloaded file into disk
1. Edit variables.tf file, set "credential_file" to point to the downloaded JSON file (needs to be locally)
1. Edit variables.tf to set the variable called: "project" to the name of the created project. (The value can be easily found in the JSON file too!)
1. Initialize plugins:
> terraform init
1. Run it: 
> terraform apply 




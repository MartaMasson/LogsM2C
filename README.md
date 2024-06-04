# Introduction 
This is a lab that explores several points when provisioning cloud native applications. The application should move every single line of log files from an on premises folder, where they are generated, to a database where it´s possible to query log lines. The files can be generated any time, any quantity, any size and the application should process the files as soon as they arrive on cloud environment. 

![image](https://github.com/MartaMasson/LogsM2C/assets/37702790/2982c58b-31fb-41ff-81d3-3e709138f973)



# Requirements
1.	Each log inside each file shall be load into the database.
2.	Ensure every log is loaded into the database.
3.	The entire application shall be provisioned in private network with no public endpoint.
4.	Keep keys and secrets safe in the vault.
5.	Restrict access to the resources by the resources at minimum level.
6.	Zero touch deployment considering application and infrastructure.
7.	High available. If a node fail, a new one needs to be instanciated.
8.	Auto scaling.
9.	Cost optimization. Usage spot instances for AKS nodes.
10.	Evalute right size for pods and nodes.
11.	Present implementation design.

# Architecture and data Flow
![image](https://github.com/MartaMasson/LogsM2C/assets/37702790/6d31c7ff-dc73-4838-8344-3b4bdb54e5bd)

1.	Log files are sent from on premises environment, any time of the day, to a blob storage.
2.	Eventgrid is triggered every file written in the blob storage and sends a notification about it in servicebus in the file queue.
3.	An application running on AKS PODs consumes the file queue, reads the file in the blob storage and sends every single line in the log queue.
4.	Another application running on AKS PODs consumes log queue and writes it into CosmosDB.


# References
https://learn.microsoft.com/en-us/java/api/overview/azure/messaging-servicebus-readme?view=azure-java-stable
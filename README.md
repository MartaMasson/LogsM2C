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

# Data flow and reference architecture
![image](https://github.com/MartaMasson/LogsM2C/assets/37702790/e4a8a71c-55d5-40e2-a094-61252f63e22e)

# Implementation architecture
TODO: Explain how other users and developers can contribute to make your code better. 

# Architecture Design Records
TODO: Explain how other users and developers can contribute to make your code better. 

# Future improvements
TODO: Explain how other users and developers can contribute to make your code better. 


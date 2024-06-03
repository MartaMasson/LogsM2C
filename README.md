# Introduction 
This is a lab that I did to explore several points when provisioning cloud native applications. The application should move every single line of log files from an on premises folder, where they are generated, to a database where it´s possible to query log lines. The files can be generated any time, any quantity, any size and the application should process the files as soon as they are generated. 

![image](https://github.com/MartaMasson/LogsM2C/assets/37702790/2982c58b-31fb-41ff-81d3-3e709138f973)



# Requirements
1.	Each log inside each file shall be load into the database.
2.	Ensure every log is load into the database.
3.	The entire application shall be provisioned in private network with no public endpoint.
4.	Keep keys and secrets safe in the vault.
5.	Restrict access to the resources by the resources at minimum level.
6.	Present implementation design.
7.	Zero touch deployment considering application and infrastructure.
8.	High available. If a node fail, a new one needs to be instanciated.
9.	Auto scaling.
10.	Cost optimization. Use stop instances for AKS nodes.  
11.	Evalute right size for pods and nodes.


# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)
